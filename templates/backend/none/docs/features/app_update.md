# Feature: app update gate

<!-- @@if api -->
## What it does
On every launch the app asks your API for its platform's version record —
`GET /app-versions/{platform}` (`android` / `ios`, public, defined in
`api/openapi.yaml`) — and compares it with its own version:
- below `min_supported_version` → **forced update**: a full screen
  (`ForcedUpdatePage`) with "Update" only; back, swipe and taps outside do
  nothing.
- below `latest_version` → **optional update**: a sheet ("Update" /
  "Later") built on `showAppSheet`, so it takes the app's UI style.
Both show the version change and "What's new" as points (one per line of
`changelog_en` / `changelog_ar`; no Arabic text → the English points).

## How to ship an update notice
Update the record your API serves (`latest_version`, and
`min_supported_version` to force it, plus `store_url` and the changelogs)
once the version is live in both stores. No app release needed. There is
no Announce update workflow without a backend in this repo — automate it
on your API's side if you like (`scripts/store_live.sh` shows how to check
both stores).

## Files
- `lib/core/update/` — version parsing, decision, sheet, forced screen
- `lib/core/backend/backend.dart` — `Backend.appVersion` → the API call
  (404 → no update)

## Tests
`test/core/update/` — version parsing, update decision, sheet and forced
screen. Goldens: `update_optional`, `update_force`.

## Edge cases
- Offline / `API_BASE_URL` not set / 404 → no update shown.
- Web and desktop → skipped.
<!-- @@else -->
## What it does
Nothing yet: without a backend the app has nowhere to read the latest
version from, so the update gate (`lib/core/update/`) stays off. Add your
REST API (`scripts/add_module.sh api`) and serve
`GET /app-versions/{platform}` to turn it on.
<!-- @@endif -->
