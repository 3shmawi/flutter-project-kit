# Backend — Supabase

Postgres with row-level security (RLS), Auth, Storage and Edge Functions.
The app talks to it through `lib/core/backend/backend.dart` (`Backend.client`),
only from feature `data/` sources. Errors are mapped to `AppFailure` in
`lib/core/backend/backend_errors.dart`.

## Env keys (`env/<name>.json`)
| Key | Where to find it |
|---|---|
| `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY` | Filled by `tool/setup_secrets.sh` when `SUPABASE_ADMIN_TOKEN` + `SUPABASE_ORG` are set (it creates the project); by hand: Supabase → Project settings → API Keys (`sb_publishable_…`) |

The publishable key is safe in the app *only because* every table has RLS.

## Credentials
| Name | Where it lives | Used by |
|---|---|---|
| `SUPABASE_ADMIN_TOKEN`, `SUPABASE_ORG` | `~/.app-secrets/shared.env` — never leaves your Mac | `tool/supabase_project.py` creates the project |
| `SUPABASE_ACCESS_TOKEN` | shared.env → GitHub secret | Supabase deploy (`supabase link` / `db push`) |
| `SUPABASE_DB_PASSWORD` | apps/<repo>/app.env → GitHub secret | Supabase deploy |
| `SUPABASE_SECRET_KEY` (`sb_secret_…`) | apps/<repo>/app.env → GitHub secret | Announce update — never in `env/*.json` |

## Deploys
Changes under `supabase/` merged to `main` → `.github/workflows/supabase.yml`
runs `supabase db push` (migrations) and deploys Edge Functions (when
`supabase/functions/` exists). The project ref is read from `SUPABASE_URL` in
`ENV_PROD_JSON`. First time: Actions → **Supabase deploy** → Run workflow
(`gh workflow run supabase.yml`). By hand instead: run
`supabase/migrations/0001_app_versions.sql` in Supabase → SQL editor (or
`supabase db push`). Then fix the iOS `store_url` once the App Store id exists.
Keep migrations backward compatible: the live app keeps running while the
store review of the new version is pending.

**Keep-alive:** free Supabase projects pause after 7 days without activity.
`.github/workflows/supabase-keepalive.yml` pings the `app_versions` table every
3 days using `SUPABASE_URL` + `SUPABASE_PUBLISHABLE_KEY` from the
`ENV_PROD_JSON` secret (Actions → *Supabase keep-alive* → Run workflow to test
it). GitHub pauses scheduled workflows in repos with no commits for 60 days —
re-enable it from the Actions tab if that happens.

## Rules
- Every table has RLS enabled; schema changes go in a new file in
  `supabase/migrations/` (never edit an applied migration).
- Every new table gets `supabase/tests/<table>_rls.test.sql` (pgTAP) proving
  what `anon` and `authenticated` can and can't do. CI runs
  `supabase test db` when a PR touches `supabase/` (enable once:
  `supabase init`, commit `supabase/config.toml`).
- Server secrets live in Edge Function secrets / Vault, never in the app.
