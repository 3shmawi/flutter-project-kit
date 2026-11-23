#!/usr/bin/env python3
"""Set up this app's Firebase projects and fill env/*.json. Idempotent.

Called by tool/setup_secrets.sh, on your Mac, with the Firebase CLI logged in
(`firebase login`) — that login never leaves the Mac. For each env file:

  prod                → the prod project   (display name "<repo>")
  dev, staging        → one shared project (display name "<repo> dev"), so
                        test builds never touch production data
  1. reuses the project already in the env file, FIREBASE_PROJECT /
     FIREBASE_DEV_PROJECT (app.env), a project with that display name, or
     creates one (`firebase projects:create`, id "<repo>-<random>"),
  2. creates the Cloud Firestore database "(default)" in FIREBASE_LOCATION
     (default eur3; the location can never be changed later),
  3. registers the Android + iOS apps for that flavor's bundle id and fills
     the empty FIREBASE_* keys from their SDK config,
  4. with gcloud logged in (`gcloud auth login`): creates the CI service
     account github-deploy@<prod project> with the deploy roles on every
     project, and its JSON key in apps/<repo>/firebase-deploy.json
     (FIREBASE_SERVICE_ACCOUNT_JSON_PATH in app.env), uploaded as the
     FIREBASE_SERVICE_ACCOUNT_JSON secret by setup_secrets.sh.
Values already in an env file are never overwritten.

Environment: REPO_NAME, PACKAGE_ID, APP_DIR, APP_ENV, DRY_RUN=true|false,
FIREBASE_PROJECT, FIREBASE_DEV_PROJECT, FIREBASE_LOCATION, FIREBASE_ORG_ID /
FIREBASE_FOLDER_ID (parent for new projects, optional), FIREBASE_DEPLOY_ROLES
(space-separated, replaces the default roles), FIREBASE_SKIP_SERVICE_ACCOUNT.
Arguments: env/*.json files (example.json is ignored).
"""
import json
import os
import plistlib
import re
import secrets
import shutil
import subprocess
import sys

REPO = os.environ.get("REPO_NAME", "")
PACKAGE_ID = os.environ.get("PACKAGE_ID", "")
APP_DIR = os.environ.get("APP_DIR", "")
APP_ENV = os.environ.get("APP_ENV", "")
DRY_RUN = os.environ.get("DRY_RUN", "false") == "true"
LOCATION = os.environ.get("FIREBASE_LOCATION", "") or "eur3"
SA_NAME = "github-deploy"

# Roles CI needs (checked against the Firebase / Google Cloud IAM docs,
# 2026-11). A deploy that fails with "permission denied" names the missing
# permission: add its role to FIREBASE_DEPLOY_ROLES in app.env and re-run.
BASE_ROLES = [
    "roles/firebase.viewer",                    # read project metadata
    "roles/firebaserules.admin",                # Firestore + Storage rules
    "roles/datastore.indexAdmin",               # Firestore indexes
    "roles/datastore.user",                     # seed + announce app_versions
    "roles/serviceusage.serviceUsageConsumer",  # call the APIs
    "roles/serviceusage.apiKeysViewer",         # the CLI reads the API key
    # @@if push
    "roles/firebasecloudmessaging.admin",       # Announce update → push
    # @@endif
]
FUNCTIONS_ROLES = [
    "roles/cloudfunctions.developer",           # deploy 2nd-gen functions
    "roles/iam.serviceAccountUser",             # act as the runtime account
    "roles/artifactregistry.admin",             # image cleanup policy
    "roles/cloudscheduler.admin",               # scheduled functions
    "roles/secretmanager.viewer",               # functions using secrets
]
EXTRA_ROLES = {  # firebase.json key → role
    "hosting": "roles/firebasehosting.admin",
    "remoteconfig": "roles/cloudconfig.admin",
    "database": "roles/firebasedatabase.admin",
}


def say(msg):
    print(f"firebase      {msg}")


def run(cmd, check=True):
    """Run a CLI and return its stdout (never echoed: SDK configs hold keys)."""
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if check and proc.returncode != 0:
        err = (proc.stderr or proc.stdout).strip().splitlines()
        raise RuntimeError(f"{' '.join(cmd[:3])}: {err[-1] if err else 'failed'}")
    return proc


def fb(*args):
    """firebase <args> --json → its "result"."""
    proc = run(["firebase", *args, "--json", "--non-interactive"], check=False)
    try:
        out = json.loads(proc.stdout)
    except json.JSONDecodeError:
        raise RuntimeError(f"firebase {args[0]}: {proc.stderr.strip() or 'no JSON output'}")
    if out.get("status") != "success":
        raise RuntimeError(f"firebase {args[0]}: {out.get('error', 'failed')}")
    return out.get("result")


def read_json(path):
    with open(path) as f:
        return json.load(f)


def write_json(path, data):
    with open(path, "w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")


def set_app_env(key, value):
    lines = []
    if os.path.exists(APP_ENV):
        with open(APP_ENV) as f:
            lines = [l for l in f.read().splitlines() if not l.startswith(f"{key}=")]
    lines.append(f"{key}={value}")
    with open(APP_ENV, "w") as f:
        f.write("\n".join(lines) + "\n")
    os.chmod(APP_ENV, 0o600)


def new_project_id(suffix):
    base = re.sub(r"[^a-z0-9]+", "-", REPO.lower()).strip("-") or "app"
    if not base[0].isalpha():
        base = "app-" + base
    tail = f"-{suffix}" if suffix else ""
    base = base[: 30 - len(tail) - 5].rstrip("-")
    return f"{base}{tail}-{secrets.token_hex(2)}"


def resolve_project(group, env_files, projects):
    for path in env_files:
        pid = read_json(path).get("FIREBASE_PROJECT_ID", "")
        if pid:
            return pid, False
    override = os.environ.get("FIREBASE_PROJECT" if group == "prod" else "FIREBASE_DEV_PROJECT", "")
    if override:
        return override, False
    display = REPO if group == "prod" else f"{REPO} dev"
    for p in projects:
        if p.get("displayName") == display:
            return p["projectId"], False
    pid = new_project_id("" if group == "prod" else "dev")
    if DRY_RUN:
        say(f"would create  project {pid} ({display})")
        return pid, True
    args = ["projects:create", pid, "--display-name", display[:30]]
    if os.environ.get("FIREBASE_ORG_ID"):
        args += ["--organization", os.environ["FIREBASE_ORG_ID"]]
    elif os.environ.get("FIREBASE_FOLDER_ID"):
        args += ["--folder", os.environ["FIREBASE_FOLDER_ID"]]
    fb(*args)
    say(f"created       project {pid} ({display})")
    return pid, True


def ensure_firestore(pid):
    try:
        dbs = fb("firestore:databases:list", "--project", pid) or []
    except RuntimeError:
        dbs = []
        if shutil.which("gcloud") and not DRY_RUN:
            run(["gcloud", "services", "enable", "firestore.googleapis.com", "--project", pid], check=False)
    if any(str(d.get("name", "")).endswith("/databases/(default)") for d in dbs):
        return
    if DRY_RUN:
        say(f"would create  Firestore (default) in {LOCATION} for {pid}")
        return
    fb("firestore:databases:create", "(default)", "--location", LOCATION, "--project", pid)
    say(f"created       Firestore database (default) in {LOCATION} ({pid})")


def find_app(apps, ident):
    for a in apps or []:
        if ident in (a.get("packageName"), a.get("bundleId"), a.get("namespace"), a.get("displayName")):
            return a.get("appId")
    return None


def ensure_app(pid, platform, ident, cache):
    key = (pid, platform)
    if key not in cache:
        cache[key] = fb("apps:list", platform, "--project", pid) or []
    app_id = find_app(cache[key], ident)
    if app_id:
        return app_id
    if DRY_RUN:
        say(f"would create  {platform} app {ident} in {pid}")
        return None
    flag = "--package-name" if platform == "ANDROID" else "--bundle-id"
    created = fb("apps:create", platform, ident, flag, ident, "--project", pid)
    cache[key].append(created)
    say(f"created       {platform.lower()} app {ident} ({pid})")
    return created["appId"]


def sdk_values(pid, platform, app_id):
    cfg = fb("apps:sdkconfig", platform, app_id, "--project", pid)
    contents = cfg["fileContents"]
    if platform == "ANDROID":
        data = json.loads(contents)
        info = data["project_info"]
        client = next(c for c in data["client"] if c["client_info"]["mobilesdk_app_id"] == app_id)
        return {
            "FIREBASE_PROJECT_ID": info["project_id"],
            "FIREBASE_MESSAGING_SENDER_ID": info["project_number"],
            "FIREBASE_STORAGE_BUCKET": info.get("storage_bucket", ""),
            "FIREBASE_ANDROID_API_KEY": client["api_key"][0]["current_key"],
            "FIREBASE_ANDROID_APP_ID": app_id,
        }
    plist = plistlib.loads(contents.encode())
    return {
        "FIREBASE_PROJECT_ID": plist["PROJECT_ID"],
        "FIREBASE_MESSAGING_SENDER_ID": plist["GCM_SENDER_ID"],
        "FIREBASE_STORAGE_BUCKET": plist.get("STORAGE_BUCKET", ""),
        "FIREBASE_IOS_API_KEY": plist["API_KEY"],
        "FIREBASE_IOS_APP_ID": app_id,
        "FIREBASE_IOS_BUNDLE_ID": plist.get("BUNDLE_ID", ""),
    }


def bundle_id(env_name):
    # Same suffixes as flavorizr.yaml (new_project.sh → setup_flavors).
    return PACKAGE_ID + {"dev": ".dev", "staging": ".stg"}.get(env_name, "")


def deploy_roles():
    if os.environ.get("FIREBASE_DEPLOY_ROLES"):
        return os.environ["FIREBASE_DEPLOY_ROLES"].split()
    roles = list(BASE_ROLES)
    try:
        cfg = read_json("firebase/firebase.json")
    except (OSError, json.JSONDecodeError):
        cfg = {}
    if "functions" in cfg or os.path.isdir("firebase/functions"):
        roles += FUNCTIONS_ROLES
    roles += [role for key, role in EXTRA_ROLES.items() if key in cfg]
    return roles


def ensure_service_account(prod_pid, all_pids):
    if os.environ.get("FIREBASE_SKIP_SERVICE_ACCOUNT") == "true":
        return
    if not shutil.which("gcloud"):
        say("skip          CI service account (install gcloud and run `gcloud auth login`, or follow docs/backend.md)")
        return
    active = run(["gcloud", "auth", "list", "--filter=status:ACTIVE", "--format=value(account)"], check=False).stdout.strip()
    if not active:
        say("skip          CI service account (run `gcloud auth login` once)")
        return
    email = f"{SA_NAME}@{prod_pid}.iam.gserviceaccount.com"
    key_path = os.path.join(APP_DIR, "firebase-deploy.json")
    roles = deploy_roles()
    if DRY_RUN:
        say(f"would ensure  {email} with {len(roles)} roles on {', '.join(all_pids)}")
        return
    exists = run(["gcloud", "iam", "service-accounts", "describe", email, "--project", prod_pid], check=False)
    if exists.returncode != 0:
        run(["gcloud", "iam", "service-accounts", "create", SA_NAME, "--project", prod_pid,
             "--display-name", f"GitHub deploy ({REPO})"[:100]])
        say(f"created       service account {email}")
    for pid in all_pids:
        for role in roles:
            run(["gcloud", "projects", "add-iam-policy-binding", pid, "--member", f"serviceAccount:{email}",
                 "--role", role, "--condition=None", "--quiet", "--format=none"])
    say(f"roles         {len(roles)} deploy roles on {', '.join(all_pids)}")
    if not os.path.exists(key_path):
        run(["gcloud", "iam", "service-accounts", "keys", "create", key_path, "--iam-account", email,
             "--project", prod_pid, "--quiet"])
        os.chmod(key_path, 0o600)
        say(f"created       key {key_path} — back it up with the keystore; rotate it yearly")
    set_app_env("FIREBASE_SERVICE_ACCOUNT_JSON_PATH", key_path)


def main(paths):
    if not shutil.which("firebase"):
        say("skip          Firebase setup (install the CLI: npm install -g firebase-tools, then firebase login)")
        return 0
    files = [p for p in paths if os.path.basename(p) != "example.json" and os.path.exists(p)]
    if not files:
        say("skip          no env files")
        return 0
    try:
        projects = fb("projects:list") or []
    except RuntimeError as e:
        say(f"skip          Firebase setup ({e}; run `firebase login`)")
        return 1
    groups = {}
    for path in files:
        name = os.path.splitext(os.path.basename(path))[0]
        groups.setdefault("prod" if name == "prod" else "dev", []).append((name, path))

    app_cache, pids = {}, {}
    for group, entries in groups.items():
        pid, created = resolve_project(group, [p for _, p in entries], projects)
        pids[group] = pid
        if DRY_RUN and created:
            continue
        ensure_firestore(pid)
        for env_name, path in entries:
            data = read_json(path)
            ident = bundle_id(env_name)
            filled = []
            for platform in ("ANDROID", "IOS"):
                id_key = f"FIREBASE_{platform}_APP_ID"
                if data.get(id_key) and data.get(f"FIREBASE_{platform}_API_KEY"):
                    continue
                app_id = ensure_app(pid, platform, ident, app_cache)
                if not app_id:
                    continue
                for k, v in sdk_values(pid, platform, app_id).items():
                    if v and not data.get(k):
                        data[k] = str(v)
                        filled.append(k)
            if filled and not DRY_RUN:
                write_json(path, data)
                say(f"filled        {path}: {', '.join(sorted(set(filled)))}")
            elif not filled:
                say(f"ok            {path} ({pid})")

    if "prod" in pids:
        ensure_service_account(pids["prod"], sorted(set(pids.values())))
    else:
        say("skip          CI service account (no env/prod.json)")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv[1:]))
    except (RuntimeError, KeyError, StopIteration) as e:
        say(f"error         {e}")
        sys.exit(1)
