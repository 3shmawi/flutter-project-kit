# Security

Security is tested, not assumed. Three layers run on every pull request.

## 1. App tests (`flutter test`, folder `test/security/`)
| Test | Guards against |
|---|---|
| `secrets_test.dart` | private keys, Supabase secret/service-role keys, AWS/Stripe/GitHub/Google keys or hard-coded keystore passwords in `lib/`, `android/`, `ios/`, `website/`, `supabase/`, `env/`; non-empty `env/example.json`; `.gitignore` missing env/signing entries |
| `platform_config_test.dart` | cleartext HTTP, debuggable releases, extra exported Android activities, disabled iOS App Transport Security |
| `deep_link_test.dart` | crafted/unknown deep links crashing the app or reaching unexpected screens; open redirects via query parameters |

## 2. CI `security` job
- **gitleaks** — scans the whole git history for committed secrets.
- **OSV-Scanner** — checks `pubspec.lock` against known vulnerabilities.
- **Supabase RLS tests** — `supabase test db` runs `supabase/tests/*.sql`
  (pgTAP) against a local database built from the migrations. Enable once:
  `supabase init` (creates `supabase/config.toml`), commit it.

## 3. Rules for new code (also in CLAUDE.md)
- New route → add hostile paths to `deep_link_test.dart`.
- New table → RLS on + `supabase/tests/<table>_rls.test.sql`.
- New input → tests for empty, huge, injection-like and malformed values.
- Auth → signed-out redirect tests + "user A can't touch user B's rows" RLS tests.
- Only publishable keys in the app. Server secrets live in Supabase
  (Edge Function secrets / Vault).

## If a scan fails
- Secret found → **rotate the key first**, then remove it from history.
- Vulnerable package → `flutter pub upgrade <package>`; if no fix exists,
  document the risk in `docs/decisions/`.
