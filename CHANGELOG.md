# Changelog

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
