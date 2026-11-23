# Feature: sign-in and account (__AUTH_LABEL__)

## What it does
- **Sign in / create account** with email + password (`/sign-in`), with
  "Forgot password?" (reset email) and, for a new account, a confirmation
  email when the backend asks for one.
<!-- @@if auth_social -->
- **Continue with Apple** (iOS) and **Continue with Google** (Android and
  iOS). Each button shows only once it is set up (below).
<!-- @@endif -->
- **Account** (`/account`, Settings → Account): who is signed in, **Sign
  out**, **Delete account** (asks first). Apple and Google require in-app
  account deletion for any app with accounts; `website/delete-account.html`
  is the web route for the same.
- Signed-out users who open a signed-in-only path (`AppRoutes.signedInOnly`)
  land on sign-in and return to that path afterwards. `?from=` only ever
  returns to a path inside the app.

## Architecture
- `lib/core/auth/auth.dart` — `AuthService` (backend-neutral), `Auth`
  (current user + the service), `AppUser`, `UnconfiguredAuthService`
  (used while the env file is empty: everyone is signed out).
- `lib/core/auth/backend_auth.dart` — `BackendAuthService` on
  __BACKEND_LABEL__. Wired in `core/di/dependencies.dart`.
- `lib/core/auth/auth_redirect.dart` — the router's redirect and input
  checks (pure functions, unit-tested).
- `lib/features/auth/presentation/` — `SignInPage`/`SignInView`,
  `AccountPage`/`AccountView`, `NewPasswordPage`. The pages hold the
  screen's own state (busy, error) and call `Auth.service`; views are pure.
- Errors: `AuthFailure(AuthFailureReason.x)` in `core/network/app_failure.dart`,
  mapped from backend codes in `core/backend/backend_errors.dart`, with a
  message in both ARB files. A closed Apple/Google sheet
  (`cancelled`) shows nothing.
- Analytics: the user id (never the email) is sent to PostHog with
  `identify` on sign-in and `reset` on sign-out.
<!-- @@if backend_supabase -->

## Backend (Supabase)
- `supabase/migrations/0002_profiles.sql` — `profiles` (one row per user,
  made by a trigger on sign-up, RLS: own row only, `on delete cascade`).
  Template for every user-owned table.
- `supabase/tests/profiles_rls.test.sql` — a user can't read or change
  another user's row; anon sees nothing; deleting the account deletes the
  profile.
- `supabase/functions/delete-account/` — deletes the calling user (only the
  server may). Deployed on merge with the other Edge Functions. Delete the
  user's Storage files there too if the app keeps any.

**Set up (once, Supabase dashboard → Authentication):**
1. *Sign In / Providers → Email*: on. Keep **Confirm email** on for
   production (the app shows "check your email").
2. *URL Configuration → Redirect URLs*: add `__SCHEME__://auth-callback`
   (reset and confirmation links open the app with it).
3. *Emails*: set the templates and, before launch, your own SMTP server
   (the built-in one is rate-limited).
<!-- @@if auth_social -->
4. *Providers → Apple*: on; **Client IDs** = `__PACKAGE_ID__` (and the
   dev/staging bundle ids). Native sign-in needs no Services ID or secret.
5. *Providers → Google*: on; **Client IDs** = the Web client id, then the
   iOS client id (comma-separated). Turn on **Skip nonce check** — the
   iOS Google SDK adds a nonce the app can't read.
<!-- @@endif -->
<!-- @@endif -->
<!-- @@if backend_none -->

## Backend (your REST API)
Sign-in goes to your API (`api/openapi.yaml` → `auth`, `me`), through
`lib/core/auth/backend_auth.dart`:
- `POST /auth/sign-in`, `/auth/sign-up` → a `Session` (access + refresh
  token + user). Sign-up without a session means "confirm your email".
- The session is kept in the Keychain (this device only) / Android
  Keystore-encrypted storage (`lib/core/api/token_store.dart`), never in
  SharedPreferences or logs.
- Every protected call sends `Authorization: Bearer <access token>`. On a
  401 the app calls `POST /auth/refresh` once (rotate the refresh token
  there) and repeats the call; a refused refresh signs the user out.
- `POST /auth/sign-out` revokes the refresh token; `DELETE /me` deletes
  the account and all its data (store requirement — implement it fully
  on the server, including files).
- Errors: 401 → wrong email/password, 409 → email in use, 422 with
  `{"code": "weak_password" | "invalid_email" | "email_not_confirmed"}`.
- Reset links: `POST /auth/password-reset` sends the email; the reset
  page is yours (web). Apple / Google sign-in need an endpoint of your own
  that takes the provider's ID token (not in the template).

**Your API must:** hash passwords (argon2id/bcrypt), rate-limit sign-in
and reset, keep access tokens short-lived (≈15 min), rotate refresh tokens
and revoke the whole family when an old one is reused, answer the reset
endpoint the same way for unknown emails, and check on every endpoint
that the token's user owns the data.
<!-- @@endif -->
<!-- @@if backend_firebase -->

## Backend (Firebase)
- `firebase/firestore.rules` → `users/{uid}`: only the owner, only known
  fields (`display_name` ≤ 80 chars). Template for every user-owned
  collection; tests in `firebase/tests/`.
- Delete account deletes `users/{uid}`, then the Firebase user. Firebase
  only deletes a user who signed in recently (~5 minutes), so the app
  checks first and asks to sign in again instead of deleting halfway.
  Add every other collection the user owns to `deleteAccount()`.

**Set up (once, Firebase console → Authentication → Sign-in method, for
the prod and the dev project):**
1. **Email/Password**: on. Templates (reset, verification) under
   *Templates*; set the sender name and the action URL domain.
<!-- @@if auth_social -->
2. **Apple**: on (no Services ID needed for iOS-only native sign-in).
3. **Google**: on. Note the **Web client id** it shows (Web SDK
   configuration) → `GOOGLE_WEB_CLIENT_ID`.
4. Project settings → your Android app → add the **SHA-1 and SHA-256** of
   the upload key (`keytool -list -v -keystore ~/.app-secrets/apps/__PROJECT_NAME__/upload.jks`)
   **and** of Play's app signing key (Play Console → Test and release →
   App integrity). Without them Google sign-in fails only in the store build.
<!-- @@endif -->
<!-- @@endif -->
<!-- @@if auth_social -->

## Apple and Google: app side
- **Apple** (iOS only): the *Sign in with Apple* capability is in
  `ios/Runner/Runner.entitlements`. Enable it for the App ID in the Apple
  Developer portal (Identifiers → `__PACKAGE_ID__` → Sign in with Apple).
- **Google**: in Google Cloud → APIs & Services → Credentials (the same
  project as the backend for Firebase) create OAuth clients:
  *Web application* (→ `GOOGLE_WEB_CLIENT_ID`), *iOS* with bundle id
  `__PACKAGE_ID__` (→ `GOOGLE_IOS_CLIENT_ID`) and *Android* with the
  package name and the SHA-1s above. Put both ids in every `env/*.json`
  (they're public identifiers), then run `tool/set_google_ios_client.sh`
  — it writes the reversed iOS client id into `ios/Runner/Info.plist`,
  which Google needs to return to the app. Until both ids are set the
  Google button stays hidden.
<!-- @@endif -->

## Tests
- `test/core/auth/auth_redirect_test.dart` — redirects, hostile `?from=`
  values, input checks (empty, malformed, injection-like, oversized).
- `test/features/auth/presentation/` — sign-in (errors, validation, sign-up,
  reset, cancelled social sheet, RTL, accessibility) and account (sign out,
  delete with confirm, "sign in again" case) against `FakeAuthService`
  (`test/helpers/fake_auth_service.dart`).
- `test/security/deep_link_test.dart` — signed-out users can't open
  signed-in-only screens; `?from=` can't leave the app.
- Backend rules: see the backend section above.
- Integration: `integration_test/auth_test.dart` (settings → sign-in → form
  check; signing in for real needs the backend in the env file).

## Analytics events
| Event | Properties |
|---|---|
| `auth_succeeded` | `method`: `email`, `email_sign_up`, `password_reset`, `apple`, `google` |
| `auth_failed` | `method` |
| `signed_out` | — |
| `account_deleted` | — |

## Decisions & edge cases
- Auth state is app-wide and outside the state-management library
  (`Auth.user` is a `ValueNotifier`) so the router can listen to it and the
  module works the same with bloc, Riverpod or none.
- Password reset never says whether an email has an account.
- Store review: Play's *App access* and Apple's review notes need a demo
  account (`store/play_app_content.json`, `store/ios/review_information/`).

## Demo & post
- Hook: "Sign up, sign out, delete your account — all in the app."
- Scenario: `integration_test/auth_test.dart`.
