# Feature: onboarding (first-launch welcome)

## What it does
A new install opening the app sees three short welcome pages (`/welcome`)
once, with Skip, Next and Get started, then lands on home. Swipes follow
the reading direction (right to left in Arabic). Deep links into other
screens skip it.
<!-- @@if push -->
The last page offers **Turn on notifications** — the one place a new user
is asked, in context (docs/features/push.md).
<!-- @@endif -->

## Make it yours
The slides are placeholders filled from the app's description. Edit them
before the first release, from the design in `docs/design.md`:
- text: `onboardingTitle1…3` / `onboardingBody1…3` in **both**
  `lib/l10n/app_en.arb` and `app_ar.arb`;
- icons: `AdaptiveIcons.onboardingWelcome/Feature/Ready`
  (`lib/core/adaptive/adaptive.dart`), or swap `Icon` for an illustration;
- number of pages: the `slides` list in `onboarding_page.dart`.
Keep it to three pages or fewer; each says one thing the app does for the
user, not how to use the UI.

## Architecture
- `lib/features/onboarding/data/onboarding.dart` — `Onboarding.seen`
  (SharedPreferences, loaded in `core/di/dependencies.dart`) and
  `onboardingRedirect` (used by `core/router/app_redirect.dart`).
- `presentation/onboarding_view.dart` — pure UI (`OnboardingSlide`s in,
  `onDone(skipped)` out); `onboarding_page.dart` — the slides, analytics,
  completion.
- Integration tests call `skipFirstLaunch(tester)` after `app.main()`
  (`integration_test/helpers/demo.dart`).

## Tests
- `test/features/onboarding/onboarding_test.dart` — redirect, saved state,
  Next / Skip / Get started, RTL swipe, accessibility.

## Analytics events
| Event | Properties |
|---|---|
| `onboarding_completed` | `skipped`: bool |

## Demo & post
- Hook: "First launch, three swipes, you're in."
