# Feature: push notifications (Firebase Cloud Messaging)

## What it does
- **Settings → Notifications** shows the permission (On / Off / Turn on).
  The system prompt appears only when the user taps *Turn on* — never on
  the first launch (ask in context; add more places that call
  `Push.service.requestPermission()` where a notification clearly helps).
  When it was denied, the row says where to turn it on.
- Everyone who allowed notifications is subscribed to the update topic in
  their language (`updates_en` / `updates_ar`).
- **Tapping a notification** opens its `data.route` — only a path inside
  the app (`Push.routeOf`, tested like deep links). While the app is open,
  a notification shows as a snack bar.
- **Actions → Announce update → push ✓** also sends "<app> <version>" +
  What's new to both topics (`scripts/send_push.sh`, FCM HTTP v1 API).

## Architecture
- `lib/core/push/push.dart` — `PushService` (provider-neutral), `Push`
  (permission + service), `Push.routeOf`, `Push.updatesTopic`.
- `lib/core/push/firebase_push.dart` — FCM (`firebase_messaging`).
<!-- @@if backend_supabase -->
- `lib/core/push/firebase_options_env.dart` — this app's data is on
  Supabase; Firebase is used only for FCM, with the `FIREBASE_*` values in
  `env/<flavor>.json` (public identifiers, like `google-services.json`).
<!-- @@endif -->
- Native: `aps-environment` in `ios/Runner/Runner.entitlements` (Xcode sets
  it to production when exporting for TestFlight / the App Store),
  `remote-notification` background mode in `Info.plist`. Android 13+'s
  `POST_NOTIFICATIONS` permission comes from the `firebase_messaging`
  plugin's manifest.

## Set up
Check Firebase's and Apple's current docs while you do this; note the date.
<!-- @@if backend_supabase -->
1. Create a Firebase project (console.firebase.google.com) for push only,
   and register the Android app (`__PACKAGE_ID__`, plus `.dev` / `.stg`
   for flavors) and the iOS app. From each app's config copy the values
   into every `env/*.json`: `FIREBASE_PROJECT_ID`,
   `FIREBASE_MESSAGING_SENDER_ID`, `FIREBASE_ANDROID_API_KEY` / `_APP_ID`,
   `FIREBASE_IOS_API_KEY` / `_APP_ID`, `FIREBASE_IOS_BUNDLE_ID`.
<!-- @@else -->
1. The Firebase project and apps already exist (`tool/setup_secrets.sh`).
<!-- @@endif -->
2. **APNs:** Apple Developer → Keys → create a key with *Apple Push
   Notifications service (APNs)*, download the `.p8` once, and upload it in
   Firebase → Project settings → Cloud Messaging → Apple app configuration
   (Key ID + Team ID). Enable *Push Notifications* for the App ID
   (Identifiers → `__PACKAGE_ID__`).
3. **Sending from CI** (Announce update → push):
<!-- @@if backend_supabase -->
   Google Cloud → IAM & Admin → Service accounts in the Firebase project →
   create `fcm-sender` with only the role **Firebase Cloud Messaging API
   Admin** → Keys → add a JSON key. Save it outside the repo, set
   `FCM_SERVICE_ACCOUNT_JSON_PATH=<path>` in
   `~/.app-secrets/apps/__PROJECT_NAME__/app.env` and run
   `tool/setup_secrets.sh` (uploads `FCM_SERVICE_ACCOUNT_JSON`; Announce
   update reads the project id from `ENV_PROD_JSON`). Delete the local key
   once it's uploaded if you don't need it.
<!-- @@else -->
   nothing to do: `tool/setup_secrets.sh` gives the CI service account
   (`github-deploy`) the role **Firebase Cloud Messaging API Admin**.
   Existing projects: run it again to add the role.
<!-- @@endif -->
4. Test: allow notifications in the app, then Firebase console → Messaging
   → New campaign → Notification → target topic `updates_en`, with custom
   data `route` = `/settings`.

## Sending to one user
Topics reach everyone. For per-user messages (a reply, a reminder), save
the device's FCM registration token on the backend with the user id when
it changes (`FirebaseMessaging.instance.onTokenRefresh`), and send from a
server (Cloud Function / Edge Function) with the HTTP v1 API — never from
the app. Add the token table/collection's access rules and tests like any
user-owned data.

## Store and privacy
- Privacy policy: Firebase Cloud Messaging is listed (`website/privacy.html`).
- Play Data safety: FCM uses a device identifier for delivery; declare
  "Device or other IDs" (collected, not shared, app functionality) if your
  Play form asks for it.

## Tests
- `test/core/push/push_test.dart` — `routeOf` with hostile data (other
  hosts, schemes, `//`, oversized, wrong types), topics by language, the
  Settings row (asks only on tap; explains when denied).
- Integration: `integration_test/push_test.dart` (the Settings row).

## Analytics events
None by default; PostHog's screen tracking shows notification opens as
navigation to the route.

## Demo & post
- Hook: "Your users hear about every update — in their own language."
