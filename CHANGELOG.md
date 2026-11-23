# Changelog

## Unreleased

- **Push notifications module:** `PUSH=none|fcm` (Create project → *Push
  notifications*), with either backend (a Supabase app uses a Firebase
  project only for FCM, options from `env/*.json`). Settings →
  Notifications asks for permission on tap, not at launch; users are
  subscribed to `updates_en` / `updates_ar`; a tapped notification opens
  its `route` only when it's a path inside the app; foreground
  notifications show as a snack bar. **Announce update** gets a *push*
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
