#!/usr/bin/env python3
"""Uploads release secrets to Codemagic (used by tool/setup_secrets.sh).

Adds the GitHub repo to Codemagic if it isn't there yet, then writes every
file in STAGE_DIR (file name = variable name, content = value) as a secure
variable in the group GROUP. Re-running replaces existing values.

Env: CODEMAGIC_API_TOKEN, REPO (owner/name), GROUP, STAGE_DIR,
     CODEMAGIC_TEAM_ID (optional). Values never appear in argv or output.
API: https://docs.codemagic.io/rest-api/applications/ (x-auth-token header).
"""
import json
import os
import sys
import urllib.error
import urllib.request

API = os.environ.get("CODEMAGIC_API_URL", "https://api.codemagic.io")
TOKEN = os.environ["CODEMAGIC_API_TOKEN"]
REPO = os.environ["REPO"]
GROUP = os.environ["GROUP"]
STAGE = os.environ["STAGE_DIR"]
TEAM = os.environ.get("CODEMAGIC_TEAM_ID", "")


def call(method, path, body=None):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(API + path, data=data, method=method)
    req.add_header("x-auth-token", TOKEN)
    req.add_header("Accept", "application/json")
    if data is not None:
        req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req, timeout=60) as res:
            raw = res.read().decode() or "null"
    except urllib.error.HTTPError as e:
        detail = e.read().decode(errors="replace")[:500]
        sys.exit(f"codemagic: {method} {path} → HTTP {e.code}: {detail}")
    try:
        return json.loads(raw)
    except ValueError:
        return raw


def walk(node):
    """Yields every dict inside a JSON response, whatever its nesting."""
    if isinstance(node, dict):
        yield node
        for value in node.values():
            yield from walk(value)
    elif isinstance(node, list):
        for item in node:
            yield from walk(item)


def ident(obj):
    return obj.get("_id") or obj.get("id")


def find_app():
    wanted = REPO.lower()
    for obj in walk(call("GET", "/apps")):
        if not ident(obj):
            continue
        text = json.dumps(obj).lower()
        if f"github.com/{wanted}" in text or f"github.com:{wanted}" in text:
            return ident(obj)
    return None


def main():
    app_id = find_app()
    if app_id:
        print(f"codemagic     app {app_id} (already added)")
    else:
        body = {"repositoryUrl": f"https://github.com/{REPO}.git"}
        if TEAM:
            body["teamId"] = TEAM
        created = call("POST", "/apps", body)
        app_id = next((ident(o) for o in walk(created) if ident(o)), None)
        if not app_id:
            sys.exit(f"codemagic: couldn't read the new app id from: {created}")
        print(f"codemagic     added app {app_id} for {REPO}")

    existing = {}
    for obj in walk(call("GET", f"/apps/{app_id}/variables")):
        if "key" in obj and ident(obj):
            group = obj.get("group")
            if isinstance(group, dict):
                group = group.get("name")
            if group in (None, GROUP):
                existing.setdefault(obj["key"], []).append(ident(obj))

    for name in sorted(os.listdir(STAGE)):
        with open(os.path.join(STAGE, name), encoding="utf-8") as f:
            value = f.read()
        for old_id in existing.get(name, []):
            call("DELETE", f"/apps/{app_id}/variables/{old_id}")
        call("POST", f"/apps/{app_id}/variables",
             {"key": name, "value": value, "group": GROUP, "secure": True})
        print(f"set           {name} (codemagic group {GROUP})")

    print(f"codemagic     app id: {app_id}")


if __name__ == "__main__":
    main()
