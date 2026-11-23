# Feature: usage-data consent

## What it does
Product analytics (PostHog) and session replays (Clarity) are **opt-in**:
nothing is sent — not even feature-flag requests — until the user allows
it.
- On the home screen of a new install (after onboarding, if any) a sheet
  asks once: **Allow** / **Don't allow**, both shown the same way (no
  nudging). Closing it without answering asks again next launch.
- **Settings → Privacy → Share usage data** changes the answer any time;
  turning it off stops PostHog (`optOut`) and pauses Clarity at once.
- The sheet and the Settings group appear only when the env file has a
  PostHog key or a Clarity id (no SDK, nothing to ask).
- Crash reports (Sentry) don't depend on it: they keep the app working
  and hold no usage data (listed separately in the privacy policy).

Things to know: feature flags (PostHog) are off for users who said no, so
a flag-gated feature must have a sensible "off" state. Screen-view
tracking starts on the launch after the user allows it.

## Architecture
- `lib/core/privacy/consent.dart` — `Consent.analytics`
  (`unknown` / `granted` / `denied`, saved with SharedPreferences, loaded
  in `bootstrap.dart` before analytics start).
- `lib/core/privacy/consent_sheet.dart` — `ConsentSheet` (pure UI) and
  `ConsentListener` (in `AppShell`, asks on home).
- `lib/core/analytics/analytics.dart` and `lib/core/monitoring/` follow
  `Consent.analytics`.
- Settings: `SettingsSwitchRow` in `SettingsModuleSections`.

## Tests
- `test/core/privacy/consent_test.dart` — default off, saved answer,
  corrupted value, equal buttons, accessibility, RTL, the switch row.
- Integration tests answer the sheet with `skipFirstLaunch(tester)`.

## Analytics events
None (asking about analytics through analytics would be the wrong order).
