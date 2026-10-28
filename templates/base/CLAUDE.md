# __APP_NAME__

__DESCRIPTION__

This file is the source of truth for anyone — human or AI agent — working on
this project. Read it fully before changing code. Feature details live in
`docs/features/`.

## Stack (decided at creation — see docs/decisions/)

| Area | Choice |
|---|---|
| Flutter | pinned in `.fvmrc` (FVM) — CI and Codemagic use the same version |
| Package / bundle ID | `__PACKAGE_ID__` |
| Environments | __ENVS_LABEL__ (`env/<name>.json`, flavors when > 1) |
| Architecture | __ARCH_LABEL__ |
| State management | __STATE_LABEL__ |
| Backend | Supabase (`lib/core/backend/`) |
| Monitoring | __MONITORING_LABEL__ (`lib/core/monitoring/`) |
| Analytics & feature flags | PostHog (`lib/core/analytics/`, `lib/core/feature_flags/`) — no Firebase |
| Routing & deep links | go_router (`lib/core/router/`), scheme `__SCHEME__://`, host `__DEEPLINK_DOMAIN__` |
| Localization | English + Arabic (RTL), ARB files in `lib/l10n/` |
| Lints | very_good_analysis (strict) |
| CI/CD | __CI_LABEL__ — merge to `main` releases to both stores |
| Website | `website/` — landing, privacy policy, terms, delete account (__WEBSITE_URL__) |

## Commands
With FVM installed, prefix with `fvm` (`fvm flutter test`, `fvm dart format .`).
Upgrade Flutter for the project: `fvm use <version>` → commit `.fvmrc`.
```bash
./scripts/run.sh [__ENV_LIST__]          # run with flavor + env file
flutter test                             # unit + widget tests
flutter test integration_test __TEST_FLAVOR_FLAG__ --dart-define-from-file=env/__DEFAULT_ENV__.json
dart fix --apply && dart format .        # fix lints, format
flutter analyze                          # must be clean
flutter gen-l10n                         # after editing .arb files
./scripts/new_feature.sh <name>          # scaffold feature + doc + test folders
```

## Project structure
```
lib/
  main.dart, bootstrap.dart   start-up: monitoring → backend → analytics → DI → app
  app/                        App (state wiring) + AppShell (MaterialApp.router)
  core/
    adaptive/                 Cupertino on iOS, Material on Android
    analytics/  feature_flags/  backend/  monitoring/
    config/                   Env (dart-define values), AppFlavor
    di/                       Dependencies — composition root
    router/                   AppRoutes (paths), appRouter, NotFoundPage
    theme/                    AppColors, AppTextStyles, AppDimens, AppTheme
    update/                   version-update gate (optional / force)
  features/<feature>/         one folder per feature (layers below)
  l10n/                       app_en.arb (template), app_ar.arb, gen/ (generated)
test/                         mirrors lib/  ·  test/helpers/pump_app.dart
integration_test/             end-to-end flows on a device
docs/                         feature docs, decisions, release, deep links
website/                      static site deployed with the app
supabase/migrations/          SQL for the backend
```

Feature layers — __ARCHITECTURE__:
- **simple**: `data/` (models, repositories, data sources) + `presentation/`
  (pages, widgets, state holders).
- **layered**: `data/` (models, data sources, repository implementations) →
  `domain/` (entities, repository interfaces, use cases — pure Dart, no
  Flutter imports except value types) → `presentation/`. Presentation depends
  on domain only; implementations are wired in `core/di/dependencies.dart`.

## Rules (non-negotiable)

**Every feature ships with**
1. Unit tests (repositories, use cases, state holders).
2. Widget tests (screens and non-trivial widgets) using `tester.pumpApp`.
3. An integration test for its main flow in `integration_test/`.
4. `docs/features/<feature>.md` (start from `./scripts/new_feature.sh`), linked
   in `docs/README.md`. Update it whenever the feature changes.

**UI**
- No hard-coded strings: add keys to `app_en.arb` **and** `app_ar.arb`, use
  `context.l10n.key`.
- No hard-coded colors, text styles or sizes: use `Theme.of(context)`,
  `AppTextStyles`, `AppDimens`, `AppColors`. New tokens go in those files.
- Sizes scale with flutter_screenutil (`.w`, `.h`, `.sp`, `.r`) — design frame
  375×812.
- RTL-safe layout: `EdgeInsetsDirectional`, `AlignmentDirectional`,
  `start`/`end` — never `left`/`right`.
- Platform-adaptive: use `.adaptive` constructors and `core/adaptive/`
  widgets; check `context.isCupertino` only inside `core/adaptive/`.
- Pages are thin: a `*_page.dart` wires state to a `*_view.dart` that only
  takes data + callbacks.

**Navigation & deep links**
- Paths live in `AppRoutes`; register routes in `app_router.dart`; document
  each path in `docs/deep_links.md`. Navigate with `context.go/push`.

**Data, errors, observability**
- Report caught errors with `Monitoring.captureException(error, stackTrace)`.
- Analytics events: `Analytics.capture('object_verb', {...})`, snake_case, and
  list them in the feature doc. No personal data in event properties.
- Gate risky or unfinished features with `FeatureFlags.isEnabled(Flags.x)`.
- Supabase: every table has RLS enabled; schema changes go in a new file in
  `supabase/migrations/`.

**Secrets**
- Nothing secret in the repo or in the app binary. `env/*.json` is
  git-ignored; CI gets values from secrets. Only publishable keys (Supabase
  anon key, PostHog key, Sentry DSN) go in env files.

**Store requirements**
- Privacy policy and terms are in `website/`; keep them accurate when adding
  data collection.
- If the app gets user accounts: in-app account deletion + the
  `website/delete-account.html` page are mandatory (Apple & Google policy).
- Keep the version-update gate (`core/update/`) working.

**Git & releases**
- Conventional Commits (enforced by `.githooks/commit-msg`):
  `feat:` → minor, `fix:` → patch, `feat!:` → major, `docs/chore/ci/test/style`
  → no release. Squash-merge PRs; the PR title is the release commit.
- Never bump versions or build by hand — CI does it (docs/release.md).
- Pre-commit runs format + analyze; don't bypass it.

## Definition of done
- [ ] `flutter analyze` clean, `dart format` applied
- [ ] Unit + widget + integration tests added and passing
- [ ] Strings in both ARB files; works in Arabic (RTL) and dark mode
- [ ] Looks right on a small phone, a large phone and a tablet
- [ ] Feature doc written/updated; analytics events listed
- [ ] Commit message follows Conventional Commits
