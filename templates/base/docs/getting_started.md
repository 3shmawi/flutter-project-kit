# Getting started

## 1. Environment files
Each environment (__ENVS_LABEL__) has `env/<name>.json` (git-ignored; the
template is `env/example.json`). Fill in:

| Key | Where to find it |
|---|---|
| `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY` | Filled by `tool/setup_secrets.sh` when `SUPABASE_ADMIN_TOKEN` + `SUPABASE_ORG` are set (it creates the project); by hand: Supabase → Project settings → API Keys (`sb_publishable_…`) |
| `POSTHOG_API_KEY`, `POSTHOG_HOST` | PostHog → Project settings → Project API key (`phc_…`) and the region: `https://eu.i.posthog.com` (EU cloud) or `https://us.i.posthog.com` (US cloud). Check both with `./scripts/check_posthog.sh` |
| `SENTRY_DSN` | Filled by `tool/setup_secrets.sh` (it creates the Sentry project if missing); by hand: Sentry → Project → Client keys |
| `CLARITY_PROJECT_ID` | Clarity → Settings (if Clarity is used) |

Every service is skipped while its key is empty, so the app runs before any
of this is set up.
`./scripts/check_env.sh env/<name>.json` names the keys that are still empty;
`tool/setup_secrets.sh` and the release build run it too (a warning on the
Actions run).

**PostHog shows no events?**
1. `./scripts/check_posthog.sh [env]` — checks the key against the host and
   sends a test event (`posthog_setup_checked`) you should see in PostHog →
   Activity. A key from the US cloud with the EU host (or the reverse) is the
   usual cause: PostHog drops those events without an error.
2. The release build reads the `ENV_PROD_JSON` secret, not your local file.
   After filling the key, upload it again (`tool/setup_secrets.sh`), then
   ship a new build: builds made before that have no key and send nothing.
   The release run shows a warning when `POSTHOG_API_KEY` is empty.
3. In a debug run, the console says `Analytics off: POSTHOG_API_KEY is empty`
   when the key didn't reach the app (`./scripts/run.sh` passes the env file).
4. Tabs (`StatefulShellBranch`) have their own navigators: give each branch
   `observers: Analytics.navigatorObservers`, or their screens aren't tracked.

## 2. Supabase
After `tool/setup_secrets.sh` has uploaded the Supabase secrets, run Actions →
**Supabase deploy** once (`gh workflow run supabase.yml`); later changes under
`supabase/` deploy on every merge to `main`. By hand instead: run
`supabase/migrations/0001_app_versions.sql` in Supabase → SQL editor (or
`supabase db push`). Then fix the iOS `store_url` once the App Store id exists.

**Keep-alive:** free Supabase projects pause after 7 days without activity.
`.github/workflows/supabase-keepalive.yml` pings the `app_versions` table every
3 days using `SUPABASE_URL` + `SUPABASE_PUBLISHABLE_KEY` from the
`ENV_PROD_JSON` secret (Actions → *Supabase keep-alive* → Run workflow to test
it). GitHub pauses scheduled workflows in repos with no commits for 60 days —
re-enable it from the Actions tab if that happens.

## 3. Run
```bash
./scripts/run.sh            # __DEFAULT_ENV__
./scripts/run.sh prod -d <device>
```
VS Code: pick a configuration in Run and Debug (one per environment).

## 4. Everyday commands
```bash
flutter test                         # unit + widget tests
flutter test integration_test __TEST_FLAVOR_FLAG__ --dart-define-from-file=env/__DEFAULT_ENV__.json
dart fix --apply && dart format .    # fix lints + format
flutter gen-l10n                     # after editing lib/l10n/*.arb
./scripts/new_feature.sh <name>      # scaffold a feature + its doc
```
