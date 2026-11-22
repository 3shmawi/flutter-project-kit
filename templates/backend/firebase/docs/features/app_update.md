# Feature: app update gate

## What it does
On every launch the app compares its version with the `app_versions` row for
its platform in Firestore (`app_versions/android`, `app_versions/ios`):
- below `min_supported_version` → **forced update**: dialog with "Update"
  only, can't be dismissed.
- below `latest_version` → **optional update**: "Update" / "Later".
The dialog shows the current and new version and the changelog in the user's
language (`changelog_en` / `changelog_ar`).

## How to ship an update notice
After the new version is live in the stores: Actions → **Announce update**
(writes the version + changelog), or edit the document in the Firebase
console → Firestore → `app_versions`: set `latest_version` (and
`min_supported_version` to force it) plus the changelog. No release needed.
The documents are created by the first **Firebase deploy**; fix the iOS
`store_url` once the App Store id exists.

## Files
- `lib/core/update/app_version.dart` — semantic version parsing/comparison
- `lib/core/update/update_info.dart` — `VersionConfig`, `evaluateUpdate()`
- `lib/core/update/update_service.dart` — the check (`Backend.appVersion`)
- `lib/core/backend/backend.dart` — reads `app_versions/<platform>`
- `lib/core/update/update_dialog.dart` — adaptive dialog
- `lib/core/update/app_update_listener.dart` — runs the check after the first frame
- `firebase/firestore.rules` (anyone reads, nobody writes from the app), `scripts/seed_app_versions.sh`

## Tests
`test/core/update/` — version parsing, update decision, dialog behaviour.

## Edge cases
- Offline / Firebase not configured / no document → no dialog.
- Web and desktop → skipped.
