# Backend — Firebase (Cloud Firestore)

Cloud Firestore with security rules; Cloud Functions, Storage, Auth and the
rest of Firebase when a feature needs them. The app talks to it through
`lib/core/backend/backend.dart` (`Backend.firestore`), only from feature
`data/` sources (layered architecture: the repository implementation in
`data/` is the only place that knows Firestore; `domain/` stays pure Dart).
Errors are mapped to `AppFailure` in `lib/core/backend/backend_errors.dart`.

```
firebase/
  firebase.json            what exists = what is deployed (see "Deploys")
  firestore.rules          security rules — deny by default
  firestore.indexes.json   composite indexes
  storage.rules            Storage rules (closed until a feature opens them)
  tests/                   rules tests on the emulators (CI runs them)
  functions/               Cloud Functions — add with `firebase init functions`
```

## Projects
| Env file | Firebase project | Apps registered |
|---|---|---|
| `env/prod.json` | `<repo>` (prod data only) | `__PACKAGE_ID__` (Android + iOS) |
| `env/staging.json`, `env/dev.json` | `<repo> dev` (shared test project) | `__PACKAGE_ID__.stg`, `__PACKAGE_ID__.dev` |

Separate projects keep test builds away from real users' data and quotas
(Firebase's own recommendation). Using one project for everything? Set
`FIREBASE_DEV_PROJECT` to the prod project id in `apps/<repo>/app.env`.

## Env keys (`env/<name>.json`)
`tool/setup_secrets.sh` fills them all. By hand: Firebase console → Project
settings → General → Your apps → the app → "SDK setup and configuration".

| Key | From |
|---|---|
| `FIREBASE_PROJECT_ID` | Project settings → Project ID |
| `FIREBASE_MESSAGING_SENDER_ID` | Project settings → Project number |
| `FIREBASE_STORAGE_BUCKET` | `google-services.json` → `storage_bucket` (empty until Storage is enabled) |
| `FIREBASE_ANDROID_API_KEY`, `FIREBASE_ANDROID_APP_ID` | Android app → `google-services.json` → `api_key.current_key`, `mobilesdk_app_id` |
| `FIREBASE_IOS_API_KEY`, `FIREBASE_IOS_APP_ID`, `FIREBASE_IOS_BUNDLE_ID` | iOS app → `GoogleService-Info.plist` → `API_KEY`, `GOOGLE_APP_ID`, `BUNDLE_ID` |

The app builds `FirebaseOptions` from these at start-up, so there is no
`google-services.json`, `GoogleService-Info.plist` or `firebase_options.dart`
in the repo and every flavor can use its own project. These values are
public identifiers, not secrets — the security rules are what protect data
(and App Check, below). While they are empty, Firebase is skipped and the app
still runs.

## Credentials — what each step needs
| Credential | Where it lives | Used by | Create it |
|---|---|---|---|
| Your Firebase login | Firebase CLI on your Mac (`firebase login`) — never leaves it | `tool/firebase_project.py`: create projects, apps, Firestore database, read SDK config | `npm install -g firebase-tools && firebase login` |
| Your Google Cloud login | gcloud on your Mac (`gcloud auth login`) — never leaves it | create the CI service account, grant its roles, make its key | [Install gcloud](https://cloud.google.com/sdk/docs/install), `gcloud auth login` |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | `apps/<repo>/firebase-deploy.json` → GitHub secret | Firebase deploy, Announce update | made by `tool/setup_secrets.sh` (see below) |
| `ENV_PROD_JSON`, `ENV_STAGING_JSON` | `env/*.json` → GitHub secrets | builds; the deploy reads `FIREBASE_PROJECT_ID` | `tool/setup_secrets.sh` |

`firebase login:ci` / `FIREBASE_TOKEN` is deprecated by the Firebase CLI —
don't use it; CI authenticates with the service account
(`GOOGLE_APPLICATION_CREDENTIALS`).

### CI credentials (service account `github-deploy@<prod project>`)
`tool/setup_secrets.sh` (with gcloud logged in) creates it in the prod
project, grants these roles on the prod **and** the dev project, and writes
its key to `~/.app-secrets/apps/<repo>/firebase-deploy.json` (back it up
with the keystore):

| Role | Why |
|---|---|
| `roles/firebase.viewer` | read project metadata |
| `roles/firebaserules.admin` | deploy Firestore + Storage rules |
| `roles/datastore.indexAdmin` | deploy Firestore indexes |
| `roles/datastore.user` | create / update `app_versions` (deploy seed, Announce update) |
| `roles/serviceusage.serviceUsageConsumer`, `roles/serviceusage.apiKeysViewer` | call the APIs; the CLI reads the project's API key |
| with `functions` in `firebase.json`: `roles/cloudfunctions.developer`, `roles/iam.serviceAccountUser`, `roles/artifactregistry.admin`, `roles/cloudscheduler.admin`, `roles/secretmanager.viewer` | deploy 2nd-gen functions (scheduled ones, ones with secrets) |
| with `hosting` / `remoteconfig` / `database`: `roles/firebasehosting.admin` / `roles/cloudconfig.admin` / `roles/firebasedatabase.admin` | those targets |

Roles were checked against the Firebase and Google Cloud IAM docs in
2026-11; Google changes them. A deploy that fails with *permission denied*
names the permission: find its role, add it to `FIREBASE_DEPLOY_ROLES`
(space-separated, replaces the list) in `apps/<repo>/app.env` and re-run
`tool/setup_secrets.sh`. **Added functions later?** Re-run
`tool/setup_secrets.sh` — it grants the functions roles once
`firebase.json` has `functions`.

No gcloud? Console → Google Cloud → IAM & Admin → Service accounts → Create
`github-deploy` → grant the roles above (prod and dev project) → Keys → Add
key → JSON → save it as `~/.app-secrets/apps/<repo>/firebase-deploy.json`,
set `FIREBASE_SERVICE_ACCOUNT_JSON_PATH=` to that path in `app.env`, re-run
`tool/setup_secrets.sh`. Organizations with the
`iam.disableServiceAccountKeyCreation` policy (default for new Google Cloud
organizations) block keys: use Workload Identity Federation (below) or an
exception for this project.

## Deploys
Changes under `firebase/` merged to `main` → `.github/workflows/firebase.yml`
deploys, for prod and (when it is another project) staging, every target
`firebase/firebase.json` lists:

| `firebase.json` key | Deployed | Notes |
|---|---|---|
| `firestore` | rules + indexes | always in the template |
| `storage` | Storage rules | only when `FIREBASE_STORAGE_BUCKET` is set (enable Storage in the console first; new buckets need Blaze) |
| `functions` | Cloud Functions (all codebases) | `npm ci` runs first; Blaze plan required |
| `database`, `remoteconfig`, `hosting`, `extensions`, `dataconnect`, `apphosting` | as configured | add them with `firebase init <product>` inside `firebase/` |

Then `scripts/seed_app_versions.sh` creates `app_versions/android` and
`app_versions/ios` if they are missing. First time: Actions → **Firebase
deploy** → Run workflow (`gh workflow run firebase.yml`).

The deploy uses `--force`: the repo is the source of truth, so functions and
indexes deleted from `firebase/` are deleted in the project. Made an index
in the console (the error link Firestore prints)? Pull it into the repo
first: `cd firebase && firebase firestore:indexes --project <id> > firestore.indexes.json`.
Keep changes backward compatible: the live app keeps running while the
store review of the new version is pending.

By hand: `cd firebase && firebase deploy --project <id>`.

## Rules
- Every collection is closed by the catch-all in `firestore.rules` and
  opened explicitly, as narrowly as possible (`request.auth.uid == userId`,
  field validation with `request.resource.data`, size limits).
- Every rule change gets cases in `firebase/tests/` proving what a
  signed-out user, the owner and another user can and can't do. CI runs
  them on the emulators when a PR touches `firebase/`; locally:
  `cd firebase/tests && npm ci && npm test` (Node 24, Java 21).
- Composite indexes go in `firestore.indexes.json`, never only in the
  console.
- Server secrets: Cloud Functions secrets (`firebase functions:secrets:set`,
  Secret Manager) — never in `env/*.json` or the app.
- CI writes with the service account (bypasses the rules); the app never
  gets more than the rules allow.

## Recommendations (in this order)
1. **Billing alert first.** Firestore bills per read/write: in
   Google Cloud → Billing → Budgets, set a small budget with e-mail alerts
   before going to Blaze. A screen that listens to a whole collection can
   cost thousands of reads per user.
2. **App Check before launch** (`firebase_app_check`: Play Integrity on
   Android, App Attest on iOS, a debug provider in dev) and turn on
   enforcement for Firestore/Storage once real traffic shows valid tokens —
   it stops scripts from using your public config.
3. **Restrict the API keys** (Google Cloud → APIs & Services → Credentials):
   Android key → package name + SHA-1 of the Play signing key, iOS key →
   bundle id; keep only the Firebase APIs the app uses.
4. **Auth** when users get accounts: add `firebase_auth`, write rules on
   `request.auth.uid`, and add in-app account deletion (store policy) — a
   Cloud Function `auth.user().onDelete` (or a callable) cleans up their data.
5. **Offline:** Firestore caches on mobile by default; cap it
   (`Settings(cacheSizeBytes: …)`) for data-heavy apps, and model reads so a
   screen needs one query (denormalize; avoid N+1 document reads).
6. **Location:** the Firestore database location (`FIREBASE_LOCATION`,
   default `eur3`) can never be changed; pick the region of your users and
   put functions in the same one.
7. **Backups:** on Blaze enable point-in-time recovery or scheduled backups
   for the prod database (`gcloud firestore backups schedules create`).
8. **Keyless CI (optional):** replace the service-account key with Workload
   Identity Federation (`google-github-actions/auth`, pinned to a commit) so
   no long-lived key exists; keep the same roles. Otherwise rotate the key
   yearly (docs/security.md → "If a key leaks").
9. **Push notifications** (`firebase_messaging`): needs an APNs key uploaded
   to Firebase and the Push Notifications capability in Xcode; FCM tokens
   are personal data — say so in the privacy policy.
10. Monitoring and analytics stay on Sentry / Clarity and PostHog
    (`lib/core/monitoring/`, `lib/core/analytics/`); no Crashlytics or Google
    Analytics, so there is one place to look.
