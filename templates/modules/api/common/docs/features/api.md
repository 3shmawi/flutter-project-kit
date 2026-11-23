# Feature: REST API (OpenAPI)

## What it does
The app talks to your REST API through a Dio client **generated from
`api/openapi.yaml`** — models, one client per tag, and every path, query
and body parameter typed. Change the contract, regenerate, and the
compiler shows every call that has to change.

```bash
dart run swagger_parser          # api/openapi.yaml → lib/core/api/gen/ (commit it)
dart run swagger_parser --check  # what CI runs: fails when gen/ is out of date
```

`swagger_parser.yaml` sets it up: plain Dio + plain models, so there is no
build_runner. Your team publishes the spec? Replace `api/openapi.yaml` with
it (or point `schema_url` at it) and regenerate.

## Set up
1. `API_BASE_URL` in every `env/*.json` (e.g. `https://api.example.com/v1`)
   — HTTPS only. `http://localhost`, `127.0.0.1` and the Android
   emulator's `10.0.2.2` work in debug builds for a local server; release
   builds refuse anything but HTTPS (`ApiConfig.checkBaseUrl`).
2. Replace the example `items` endpoints with yours, regenerate, and copy
   the pattern of `lib/features/items/data/items_repository.dart` into your
   features; delete the example.
<!-- @@if backend_supabase -->
3. Sign-in is Supabase's: the app sends the session's access token (a
   JWT). Your API verifies it with the project's JWT signing keys
   (Supabase → Project settings → JWT Keys → the JWKS URL) and reads the
   user id from `sub`.
<!-- @@endif -->
<!-- @@if backend_firebase -->
3. Sign-in is Firebase's: the app sends the user's ID token. Your API
   verifies it with the Firebase Admin SDK (`verifyIdToken`) and reads the
   user id from `uid`.
<!-- @@endif -->
<!-- @@if backend_none -->
3. Your API is the backend: sign-in, the session and account deletion go
   through it (docs/features/auth.md when sign-in is on), and the update
   gate reads `GET /app-versions/{platform}` (docs/features/app_update.md).
<!-- @@endif -->

## How a call works
`guard(() => ApiClient.api.items.listItems())` → `Result<List<Item>>`:
- **Token:** `AuthInterceptor` adds `Authorization: Bearer <token>` to
  every operation the spec doesn't mark public (`security: []`). The token
  comes from `core/api/backend_api_tokens.dart`: the Supabase session, the
  Firebase ID token, or your API's own tokens in secure storage.
- **401:** the token is refreshed once — calls that fail together share
  one refresh — and the call is repeated. A refused refresh clears the
  session and signs the user out; a refresh that can't reach the server
  keeps the session and only that call fails.
- **Errors** (`core/api/api_errors.dart`): no connection / TLS →
  `NetworkFailure`, timeout → `TimeoutFailure` (both retried by `guard`),
  401/403 → `UnauthorizedFailure`, 404 → `NotFoundFailure`, 400/409/422 →
  `ValidationFailure`, 429/5xx → `ServerFailure` (retried). A response that
  doesn't match the spec → `UnknownFailure`, reported to monitoring.
- Calls that create something use `retries: 0` (a retry after a lost
  response would create it twice), unless your API takes an idempotency key.

## Files
- `api/openapi.yaml` — the contract; `swagger_parser.yaml` — generator setup
- `lib/core/api/gen/` — generated, never edited (excluded from lints and coverage)
- `lib/core/api/api_client.dart` — `ApiClient.api`, `createDio` (timeouts, no redirects)
- `lib/core/api/api_config.dart` — `API_BASE_URL`, HTTPS check
- `lib/core/api/auth_interceptor.dart`, `api_tokens.dart`, `backend_api_tokens.dart`
- `lib/core/api/api_errors.dart` — Dio errors → `AppFailure`
- `lib/features/items/data/items_repository.dart` — example

## Tests
- `test/helpers/mock_api_server.dart` — a real local HTTP server that
  answers per route and records every request (use it in `test()`, not
  `testWidgets()`, which blocks real HTTP).
- `test/core/api/` — HTTPS rule, token, refresh (once, shared, refused,
  offline), no redirect, error mapping.
- `test/features/items/` — the example against the mock server, including
  hostile input.
- `test/security/api_security_test.dart` — no request logging, only the
  interceptor touches `Authorization`, `API_BASE_URL` is HTTPS in prod, no
  redirects.

## Security
- Tokens live only in memory and secure storage — never in
  SharedPreferences, logs, analytics or error reports. There is no logging
  interceptor; don't add one that prints headers or bodies.
- Redirects aren't followed, so a token is never sent to another host.
- The app's checks are for UX; your API must check every request (the
  token's user owns the data) and rate-limit.
- `API_BASE_URL` is public, like everything in the app. API keys that must
  stay secret belong on your server, never in `env/*.json`.

## Decisions & edge cases
- swagger_parser (pure Dart, Dio, no build_runner) over openapi-generator
  (needs Java) — checked 2026-11-23, swagger_parser 2.3.0.
- Offline → `NetworkFailure`; the global offline banner shows.
- Not configured (`API_BASE_URL` empty or not HTTPS) → calls fail with
  `UnknownFailure` and a clear message in monitoring.
