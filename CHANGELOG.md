# Changelog

## Unreleased

- **REST API module (`API=rest`, or `scripts/add_module.sh api`):** a typed
  Dio client generated from `api/openapi.yaml` with swagger_parser (no
  build_runner; CI fails when `lib/core/api/gen/` is out of date).
  `API_BASE_URL` per flavor, HTTPS only (localhost http in debug). Bearer
  token on protected operations — the Supabase JWT, the Firebase ID token,
  or the API's own tokens in the Keychain/Keystore — refreshed once on a
  401 (shared by parallel calls), sign-out when the refresh is refused,
  kept when it's only offline. No redirects, no request logging. Dio
  errors map to `AppFailure` inside `guard()`. Example `items` repository,
  a local mock server for tests, security tests. Works with every backend.
- **`BACKEND=none`:** for apps on your company's API (with `API=rest`: the
  update gate reads `GET /app-versions/{platform}`, `AUTH=email` signs in,
  refreshes, signs out and deletes the account through `/auth/*` and
  `/me`) or with local data only. Push works too (Firebase only for FCM;
  `templates/modules/push/not_firebase/`, a new `not_<backend>` folder
  convention in `copy_modules`).
- **Update prompt in the app's own style:** an optional update is now a
  sheet built on `showAppSheet` (glass in glass apps) and a forced update a
  full screen (`ForcedUpdatePage`) that back, swipe and taps outside can't
  leave. Both show the update icon, `1.0.0 → 1.1.0` and "What's new" as
  points (one per changelog line; no Arabic text → the English points).
  New goldens `update_optional` / `update_force`.
- **Optional updates announce themselves:** Announce update runs daily and,
  once a version is fully live on Google Play (production, *completed*)
  and the App Store, writes it as an optional update with that release's
  store "What's new" texts — never over a newer or hand-made notice, never
  forced. `scripts/store_live.sh`, `announce_plan.sh`, `whats_new.sh`
  (tested against fake stores). `AUTO_ANNOUNCE=false` turns it off.
- **Automatic social-publisher updates:** the weekly *Bump social-publisher*
  workflow opens a PR when social-publisher has a newer `vX.Y.Z` tag
  (social-publisher now tags itself after each release), moving the pins in
  `social.yml`, `social-health.yml` and `social-insights.yml`, and merges it
  once every check passes (a failure leaves it open). Apps already
  get new tags through their Dependabot (`github-actions`).
- **social-publisher v1.6.0:** `social.yml` is pinned to it and passes the
  new opt-in platforms' secrets (Threads, Bluesky, Telegram, X — turn them
  on in `SOCIAL_PLATFORMS`) and variables (`SOCIAL_X_LINKS`,
  `SOCIAL_POST_AT` / `SOCIAL_POST_TIMEZONE` / `SOCIAL_POST_AT_OVERRIDES`,
  `APP_STORE_PROVIDER_TOKEN`). Every app also gets
  `social-health.yml` (weekly credential check that keeps a
  `social-credentials` issue open while a token would fail, and refreshes
  the Threads token) and `social-insights.yml` (each post's numbers after
  a week). Both are off until `SOCIAL_ENABLED=true`. `tool/setup_secrets.sh`
  uploads the new secrets.
- **`scripts/add_module.sh`** adds a module (`auth=email|social`,
  `paywall`, `push`, `onboarding`) to an existing app: renders the kit at
  the app's version without and with it, 3-way merges the difference,
  adds packages, native setup and env keys, records it in
  `.project-kit.env`, refreshes goldens and commits on a branch — the
  result matches an app created with the module. `new_project.sh` gained
  `--module-packages` and `--patch-native` for it.
- **Kit sync merges more cleanly:** rendered templates now go through the
  same `dart fix --apply` as the project (import order, Dart 3.13
  constructor syntax) before the 3-way merge, instead of only
  `dart format` — far fewer false conflicts.
- **Golden tests (every app):** `test/golden/golden_test.dart` renders the
  main screens — and each module's — in light/dark × English/Arabic on
  the design frame. Text uses Flutter's test font and a 0.5 % tolerance
  comparator (`test/golden/flutter_test_config.dart`), so goldens made on
  a Mac pass on Linux CI. The generator makes the baselines; CI uploads
  `test/golden/failures/` as *golden-failures* when one breaks. Existing
  apps: after the kit sync run `flutter test --update-goldens test/golden`
  once and commit the PNGs.
- **`showAppMessage` / `appMessenger`** (`core/ui/app_message.dart`): a
  short message that works in both UI styles (the glass style has no
  Material `Scaffold` for SnackBars) and is announced by screen readers.
- **Usage-data consent (every app):** PostHog and Clarity are opt-in. A
  sheet on the home screen of a new install asks once (Allow / Don't
  allow, equal buttons), Settings → Privacy → *Share usage data* changes
  it any time; turning it off opts PostHog out and pauses Clarity at once.
  Nothing is sent before the answer, not even flag requests. Shown only
  when the env file has a PostHog key or Clarity id. Privacy policy
  updated; `docs/features/consent.md`. New `SettingsSwitchRow`;
  integration tests use `skipFirstLaunch(tester)` (onboarding + consent).
- **Fix:** the generator aborted silently for apps without modules (an
  empty `grep -v` under `pipefail`).
- **iOS privacy manifest:** every app gets `ios/Runner/PrivacyInfo.xcprivacy`
  declaring no tracking, the data its SDKs and modules collect (PostHog,
  Sentry or Clarity, sign-in email and user id, RevenueCat purchase
  history, FCM device id — linked to the user when sign-in is on) and the
  UserDefaults reason (`CA92.1`). The generator adds it to Runner's
  Resources build phase (`kit_tools/xcode_add_resource.py`, idempotent);
  `test/security/platform_config_test.dart` checks both. Existing apps:
  after the kit sync, run
  `python3 <kit>/kit_tools/xcode_add_resource.py ios/Runner.xcodeproj/project.pbxproj PrivacyInfo.xcprivacy`
  (or `scripts/add_module.sh` does it).
- **Onboarding module:** `ONBOARDING=yes` (Create project → *Onboarding*).
  Three welcome pages on a new install's first launch (`/welcome`),
  swipes in the reading direction, Skip / Next / Get started, saved on
  the device; with push, the last page offers notifications in context.
  Module redirects now share `core/router/app_redirect.dart`; integration
  tests call `skipFirstLaunch(tester)` after `app.main()`.
- **Store rating prompt (every app):** `ReviewPrompt` shows the store's
  own rating sheet (`in_app_review`) after 5 launches over 3+ days, at
  most every 120 days and once per launch, never with the update dialog,
  and only while the PostHog flag `review_prompt` is on (off by default).
  Apps call `ReviewPrompt.maybeAsk()` after happy moments.
  `docs/features/review_prompt.md`. Existing apps: `flutter pub add
  in_app_review` after the kit sync.
- **Push notifications module:** `PUSH=none|fcm` (Create project → *Push
  notifications*), with either backend (a Supabase app uses a Firebase
  project only for FCM, options from `env/*.json`). Settings →
  Notifications asks for permission on tap, not at launch; users are
  subscribed to `updates_en` / `updates_ar`; a tapped notification opens
  its `route` only when it's a path inside the app; foreground
  notifications show as an in-app message. **Announce update** gets a *push*
  input that sends the update to both topics (`scripts/send_push.sh`,
  FCM HTTP v1). The Firebase CI service account gets *Firebase Cloud
  Messaging API Admin*; Supabase apps upload `FCM_SERVICE_ACCOUNT_JSON`
  through `tool/setup_secrets.sh`. `scripts/gcp_token.sh` moved to base.
- **Paid features module:** `PAYWALL=none|revenuecat` (Create project →
  *Paid features*). RevenueCat behind a store-neutral `PurchasesService`;
  a paywall with store-localized prices, yearly first, renewal terms,
  Restore, Terms and Privacy (Apple 3.1.2); `Premium.active` and
  `PremiumGate` for premium-only UI; Settings → Premium and Restore
  purchases; `PurchaseFailure` (a closed store sheet shows nothing, a
  pending purchase says it unlocks later). With sign-in, RevenueCat's user
  follows the account. Public SDK keys `REVENUECAT_APPLE_API_KEY` /
  `REVENUECAT_GOOGLE_API_KEY` in `env/*.json`; privacy policy and Play
  answers updated. `docs/features/paywall.md` has the store and RevenueCat
  steps.
- **Modules, and sign-in as the first one:** `AUTH=none|email|social`
  (Create project → *Sign-in*). Module files live in
  `templates/modules/<module>/`; shared templates use `@@if <module>`
  blocks (`!`, `|`, `@@else`, nesting) that the generator keeps or drops,
  so kit sync keeps module code current too. Sign-in brings email +
  password sign-up/sign-in/reset, an Account screen with sign out and
  in-app **account deletion** (Apple/Google policy), signed-in-only routes
  (`AppRoutes.signedInOnly`) with a `?from=` that can't leave the app, and
  `AuthFailure` messages in both languages. Supabase: `profiles` (RLS +
  pgTAP tests, cascade on delete) and the `delete-account` Edge Function;
  Firebase: owner-only `users/{uid}` rules + emulator tests. `social` adds
  Sign in with Apple (entitlement added) and Google (`google_sign_in` 7,
  `tool/set_google_ios_client.sh` writes the iOS URL scheme). Validate kit
  generates both backends with sign-in on. Privacy policy, Play App
  content answers, deep-link docs and `docs/features/auth.md` follow the
  option. `AppFailure` now implements `Exception`.
- **Firebase as a backend option:** `BACKEND=supabase|firebase` (Create
  project → *Backend*). Backend files moved to `templates/backend/<name>/`;
  the shared code only talks to `Backend` (`init`, `isConfigured`,
  `appVersion`) and `backendFailure()`, so features, state and `domain/`
  don't depend on the backend. Firebase projects get Cloud Firestore with
  options read from `env/*.json` (one Firebase project per flavor, no native
  config files), `firebase/` (deny-by-default rules, indexes, Storage
  rules, emulator rules tests that CI runs on PRs), **Firebase deploy** on
  merge (whatever `firebase.json` lists: rules, indexes, Storage, functions,
  Remote Config, Hosting, …, then seeds `app_versions`), and **Announce
  update** writing Firestore. `tool/setup_secrets.sh` creates the prod and
  dev projects, apps, Firestore database and the least-privilege CI service
  account + key from your own `firebase login` / `gcloud auth login`.
  `docs/backend.md` per project: credentials, roles, deploys, rules,
  recommendations. Existing projects stay on Supabase (kit sync defaults
  to it).
- **Social posts on Instagram:** social-publisher v1.4.1 publishes the
  release video as an Instagram Reel with the same Page token. New secret
  `IG_USER_ID` in `tool/setup_secrets.sh`.

- **Social posts on TikTok:** social-publisher v1.3.0; the release video goes
  to your TikTok inbox as a draft. New secrets `TIKTOK_CLIENT_KEY`,
  `TIKTOK_CLIENT_SECRET`, `TIKTOK_REFRESH_TOKEN` and `SOCIAL_SECRETS_TOKEN`
  (saves TikTok's rotated refresh token) in `tool/setup_secrets.sh`;
  variable `SOCIAL_TIKTOK_TOKEN_REPOS`.

- **Settings, closer to iOS:** the rows use SF Symbols-style icons on iOS
  (`AdaptiveIcons.language/theme/privacy/terms/licenses/info`, Material
  outlines on Android) and a chevron that mirrors in Arabic; Language and
  Theme open `showAppSheet`, a new shared sheet in `app_ui.dart`: frosted
  glass with a grab handle in the glass UI style (solid in lite mode), a
  Material sheet with a drag handle in the adaptive style. Same layout as
  yaani_eh's settings.
- **Social posts without API credit:** Claude now writes the posts on your
  Claude Pro/Max plan (`CLAUDE_CODE_OAUTH_TOKEN` from `claude setup-token`)
  instead of `ANTHROPIC_API_KEY`; without the token, fixed English and Arabic
  templates fill in from the store "What's new" text. `SOCIAL_HASHTAGS`
  variable for template posts.
- **Social posts:** `.github/workflows/social.yml` calls the reusable
  workflow in [3shmawi/social-publisher](https://github.com/3shmawi/social-publisher):
  Claude writes LinkedIn, Facebook Page and YouTube posts (English + Arabic)
  from the release notes, or every two weeks from the changes since the last
  post; you approve them in the `social` environment, then each platform
  posts independently and never twice. GitHub-CI `release.yml` starts it
  after the GitHub release (a release made with the job token starts no
  workflows); Codemagic's `v*` tag push starts it there. Off until
  `SOCIAL_ENABLED=true`, dry runs until `SOCIAL_LIVE=true`.
  `tool/setup_secrets.sh` uploads its secrets (always to GitHub, Codemagic
  projects too). Setup: `docs/release.md` → "Social posts".
- **Agents run the app on iOS and Android (Dart MCP server):** the official
  Dart & Flutter plugin (`flutter/agent-plugins`, pinned to a commit) is in
  `.claude/settings.json`. `scripts/agent_run.sh ios|android [env]` boots a
  simulator / emulator, runs the app with the env file and the Flutter
  Driver extension (`test_driver/agent_app.dart`, debug only) and prints
  the DTD URI; the agent connects the MCP server to it and taps, types,
  takes screenshots, reads runtime errors and hot reloads (CLAUDE.md →
  "Running the app as an agent"). `reload`, `restart`, `shot`, `stop`,
  `status` subcommands. `test/security/agent_driver_test.dart` keeps
  `flutter_driver` out of `lib/`. The README's cloud setup script installs
  the plugin too.
- **Settings, grouped rows:** the settings screen uses the iOS layout
  (from gym_tracker and yaani_eh): groups of compact rows with an icon,
  the current value and a chevron. Language and theme open a sheet to
  pick (closing it changes nothing); About adds the privacy policy and
  terms (`lib/core/legal/legal_links.dart`, from the project website, hidden
  while there is no https site) and open-source licenses.
- **Store listing on a busy Play track:** the job reads the newest version
  code on `PLAY_TRACK` and passes it to supply, so a track with several
  releases no longer fails with "More than one release found".
- **App Review contact:** `APP_REVIEW_FIRST_NAME/LAST_NAME/EMAIL/PHONE`
  secrets (in `tool/setup_secrets.sh`) go to deliver through the
  `Deliverfile`; Apple refuses review notes without them. Unset, the notes
  are skipped with a warning instead of failing the job.
- **What's new from the repo:** `store/ios/<locale>/release_notes.txt` and
  `store/android/<locale>/changelogs/default.txt`, in Arabic and English,
  uploaded by Store listing (on Play to the latest release of `PLAY_TRACK`).
- **App Store header and search results:** `store/tools/hero.js` makes
  Apple's iOS 27 creative assets (3840×1646 header, 3840×2560 search
  results) from the app's real screens, text inside the art safe area;
  uploaded by hand in App Store Connect. `listing_test.dart` checks their sizes.
- **Play Console App content answers:** `store/play_app_content.json`, one
  section per Play Console screen, shown by `store/tools/app_content.html`
  with a copy button per answer and a checkmark per step; the agent fills
  the `TODO`s from the code when it prepares the stores, and
  `listing_test.dart` refuses them in a release.
- **App Store copyright:** `store/ios/copyright.txt` (`<year> <developer>`), which App
  Store Connect requires on every version; uploaded by Store listing.

- **Store images from the real app:** `test/store/store_screenshots_test.dart`
  renders the screens listed in `test/store/store_screens.dart`, and
  `store/tools/make.js` frames them into every size both stores need
  (iPhone 6.9", iPad 13", Play phone and 7"/10" tablets), plus the Play
  feature graphic and 512 icon, in Arabic and English. `listing_test.dart`
  checks the sizes and that no image has an alpha channel.
- **Store listing workflow fixes:** iOS no longer crashes on deliver's setup
  prompt (empty `Deliverfile`, locale folder check skipped for
  `screenshots/`) nor on a version without App Review Information
  (`store/ios/review_information/notes.txt`, checked for `TODO` like the
  other texts); Android saves the edit without sending it for review, so the
  service account needs no production permission; Play images are uploaded
  when a feature graphic exists. `docs/release.md` lists the Play service
  account permissions Store listing needs, including "Edit and delete draft
  apps" while the app is a draft.

## 1.0.0 — first public release

- **Generator, cloud or local:** create an app from GitHub Actions
  (**Create project**, runs on a macOS runner, nothing installed on your Mac)
  or with `./new_project.sh` on your Mac, interactively or from an answers file.
- **Options:** environments (dev + staging + prod, staging + prod, or prod
  only, with flavors), simple or layered architecture, BLoC / Riverpod / no
  state library, Sentry / Clarity / no monitoring, GitHub Actions or
  Codemagic, brand color and fonts, UI style, deep-link domain.
- **Automatic releases:** merging to `main` picks the version from
  Conventional Commits, builds obfuscated releases and uploads them to Google
  Play and TestFlight / App Store Connect, with symbols and release notes.
  `develop` ships staging builds.
- **Update dialog:** optional or forced in-app updates driven by an
  `app_versions` row in Supabase, announced from an Actions button.
- **Arabic and English with RTL:** ARB files, RTL-safe layouts and bundled
  Latin and Arabic fonts.
- **Store listings as code:** titles, descriptions, keywords and screenshots
  in `store/`, pushed to both stores from an Actions button.
- **Website:** landing page, privacy policy, terms and a delete-account page,
  plus the `.well-known` files for deep links, deployed with the app.
- **Tests:** unit, widget, accessibility, security and integration tests,
  coverage gate, secret and dependency scans, and workflow security checks
  on every PR.
- **Kit self-validation:** **Validate kit** generates several option
  combinations with the real Flutter SDK and requires analyze, tests and
  Android + iOS debug builds to pass on every change and weekly.
- **Kit sync:** existing apps get kit updates as a pull request.
