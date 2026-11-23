# Feature: store rating prompt

## What it does
Shows the store's own rating sheet (App Store / Google Play in-app review)
when it's polite to ask:
- after **5 launches** over at least **3 days**,
- at most **once every 120 days** and once per launch,
- only while the PostHog flag **`review_prompt`** is on (off until you
  create it — turn it on once the app is stable and crash-free),
- never in the same launch as the update prompt.

The stores decide whether the sheet really appears (Apple: at most 3 times
a year per user; Google: a quota), and the app is never told what the user
rated. Never ask through your own "Rate us 5 stars" screen first — both
stores forbid steering ratings.

## Use it
The kit tries once per launch (`core/update/app_update_listener.dart`).
Better moments are right after something went well — call
`ReviewPrompt.maybeAsk()` there (a task finished, a goal reached), never
after an error or in the middle of a flow.

Tune the rules in `ReviewPolicy` (`lib/core/review/review_prompt.dart`).

## Architecture
- `lib/core/review/review_prompt.dart` — `ReviewPolicy` (pure, tested) and
  `ReviewPrompt` (`recordLaunch` from `core/di/dependencies.dart`,
  `maybeAsk`). Counts live in SharedPreferences on the device.
- Package: `in_app_review`.

## Tests
- `test/core/review/review_prompt_test.dart` — the policy, the flag, once
  per launch, store errors swallowed.

## Analytics events
| Event | Properties |
|---|---|
| `review_prompt_requested` | — |
