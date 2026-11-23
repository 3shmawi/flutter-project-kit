# Feature: app update gate

## What it does
On every launch the app compares its version with the `app_versions` row for
its platform in Supabase:
- below `min_supported_version` → **forced update**: a full screen
  (`ForcedUpdatePage`) with "Update" only; back, swipe and taps outside do
  nothing.
- below `latest_version` → **optional update**: a sheet ("Update" /
  "Later") built on `showAppSheet`, so it takes the app's UI style (glass
  in glass apps).
Both show the update icon, the version change (`1.0.0 → 1.1.0`, read out
as one sentence by screen readers) and "What's new" as points — one per
line of `changelog_en` / `changelog_ar` in the user's language (list
markers like `-`, `•`, `1.` are removed; no Arabic text → the English
points). Arabic is right-to-left; the version numbers stay left-to-right.

## How to ship an update notice
Optional updates are announced for you: Actions → **Announce update**
runs daily and, once the version is fully live on Google Play and the App
Store, writes it as an optional update with the store "What's new" texts
(docs/release.md → "After the stores approve"; `AUTO_ANNOUNCE=false`
turns it off). To force an update or announce by hand: Actions →
**Announce update**, or edit the row in Supabase → Table editor →
`app_versions`: set `latest_version` (and `min_supported_version` to force
it) plus the changelog. No release needed.

## Files
- `lib/core/update/app_version.dart` — semantic version parsing/comparison
- `lib/core/update/update_info.dart` — `VersionConfig`, `evaluateUpdate()`
- `lib/core/update/update_service.dart` — the check (`Backend.appVersion`)
- `lib/core/backend/backend.dart` — the Supabase query
- `lib/core/update/update_dialog.dart` — optional sheet, forced screen (`ForcedUpdatePage`), `changelogPoints`
- `lib/core/update/app_update_listener.dart` — runs the check after the first frame
- `supabase/migrations/0001_app_versions.sql`

## Tests
`test/core/update/` — version parsing, update decision, sheet and forced
screen (accessibility, Arabic, can't leave a forced update).
`test/scripts/announce_scripts_test.dart` — the daily check against fake
stores (`store_live.sh`, `announce_plan.sh`, `whats_new.sh`).
Goldens: `update_optional`, `update_force` in `test/golden/golden_test.dart`.

## Edge cases
- Offline / Supabase not configured / no row → no dialog.
- Web and desktop → skipped.
- A staged rollout on Play, or the App Store not updated yet → the daily
  check waits; it never forces.
- The live version has no `v<version>` tag → a warning, nothing written.
