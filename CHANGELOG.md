# Changelog

## Unreleased

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
