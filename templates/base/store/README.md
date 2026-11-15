# Store listings (as code)

Edit the text files, open a PR, then run **Actions → Store listing**
(manual) to upload them. Google Play uses `store/android/<locale>/`, the App
Store uses `store/ios/<locale>/` — fastlane `supply` / `deliver` layouts.

| File | Limit |
|---|---|
| android `title.txt` | 30 chars |
| android `short_description.txt` | 80 chars |
| android `full_description.txt` | 4000 chars |
| ios `name.txt`, `subtitle.txt` | 30 chars each |
| ios `keywords.txt` | 100 chars, comma-separated |
| ios `promotional_text.txt` | 170 chars |
| ios `description.txt` | 4000 chars |
| ios `copyright.txt` | App Store "Copyright", one line: `<year> <owner>` (no ©); update the year when it changes |
| ios `review_information/notes.txt` | App Review notes (how to try the app); required, see docs/release.md |

`test/store/listing_test.dart` fails if a limit is exceeded or a placeholder
("Feature one", "keyword1", "اكتب هنا") is still there when you run the
upload workflow.

## Screenshots and graphics
Made from the app's **real screens** (widget-test renders, dark mode), framed
with a headline, in Arabic and English. Sizes checked 2026-11-15 against
Apple's "Screenshot specifications", Google Play's "Add preview assets" and
fastlane 2.241.2's display types; `test/store/listing_test.dart` checks them.

| Store | Files | Size |
|---|---|---|
| App Store, iPhone 6.9" | `ios/screenshots/<locale>/N_iphone69.png` (up to 10) | 1320×2868 |
| App Store, iPad 13" (required when the app runs on iPad) | `ios/screenshots/<locale>/N_ipad13.png` (up to 10) | 2064×2752 |
| Google Play, phone | `android/<locale>/images/phoneScreenshots/N.png` (up to 8) | 1080×1920 |
| Google Play, 7" tablet | `android/<locale>/images/sevenInchScreenshots/N.png` | 1080×1920 |
| Google Play, 10" tablet | `android/<locale>/images/tenInchScreenshots/N.png` | 1440×2560 |
| Google Play, feature graphic (the listing's header) | `android/<locale>/images/featureGraphic.png` | 1024×500 |
| Google Play, hi-res icon | `android/<locale>/images/icon.png` | 512×512 |

No image may have an alpha channel (except the Play icon). The App Store
shows the first three screenshots in search results: put the core story
there. The App Store icon comes from the build.

**Make them (or again after a UI change):**
1. List the screens in `test/store/store_screens.dart`, built with sample
   data like their widget tests. Only features that are live for every user
   in prod (check the feature flags).
2. Render them:
   `flutter test test/store/store_screenshots_test.dart --update-goldens --dart-define=STORE_SHOTS=true`
   → `store/tools/raw/` (git-ignored).
3. Write the headlines in `store/tools/shots.json` (order = store order;
   Arabic and English; no `TODO` left) and the feature graphic's texts.
4. `cd store/tools && npm install && npx playwright install chromium && node make.js`
   writes every image above into `store/`. Look at them before committing.
5. Fill the store texts (limits above), open a PR, merge, run **Store
   listing**, then Play Console → Publishing overview → Send changes for
   review.

Alt text for the Play images (140 characters at most) is typed in Play
Console; fastlane doesn't upload it.
