# Release & CI/CD (__CI_LABEL__)

**You never build by hand.** Open a PR → checks run. Merge to `main` → a new
version is built and uploaded to Google Play and App Store Connect.

## How the version is chosen
`scripts/next_version.sh` reads the Conventional Commit messages merged since
the last `v*` tag (squash-merge PRs so the PR title is the commit):

| Commits | Result |
|---|---|
| `feat: …` | minor — 1.4.2 → 1.5.0 |
| `fix:` / `perf:` / `refactor:` / anything else | patch — 1.4.2 → 1.4.3 |
| `feat!: …` or `BREAKING CHANGE:` in the body | major — 1.4.2 → 2.0.0 |
| only `docs:` `chore:` `ci:` `test:` `style:` | no release |

The build number is the CI run number (plus the optional `BUILD_NUMBER_OFFSET`
repository variable). The first release uses the version in `pubspec.yaml`.
A manual run (Actions → Release → Run workflow) can force patch/minor/major.

## Pipeline
1. **Checks** — format, analyze, unit/widget tests. PRs also run every
   integration test on an iPhone simulator (macOS runner, full Liquid Glass)
   and build a debug Android APK. Android flows aren't run in CI: the
   GitHub-hosted emulator has no GPU and went offline at the end of every
   app run, losing the results. Run them on a phone or local emulator when
   a change is Android-specific.
   The iOS integration job is the slow one, so it runs only when the PR
   changes something the app is built from (`lib/`, `ios/`,
   `integration_test/`, `assets/`, `env/`, pubspec, `.fvmrc`, `ci.yml`,
   `.github/actions/`);
   otherwise it is skipped (a skipped job counts as passed). It caches Swift
   packages, DerivedData and `build/ios` (`actions/cache` v6.1.0, checked
   2026-11-01; saved after green runs only), so later builds are
   incremental.
   Every job sets up Flutter through one shared action,
   `.github/actions/setup-flutter`: the version from `.fvmrc`, the SDK and
   pub packages cached (`subosito/flutter-action` v2.23.0), and for Android
   Java 17. PR builds also cache Gradle (`actions/setup-java` v6.1.0
   `cache: gradle`, checked 2026-11-01). Release and staging builds don't
   (see `docs/security.md` → "CI and secrets"). Change caching or versions in
   that one file; it reaches other projects through `kit_sync.sh`.
2. **Android** — signed release AAB (prod) → Play track `PLAY_TRACK`
   (default `internal`).
3. **iOS** — signing files fetched from App Store Connect with the API key →
   IPA → App Store Connect / TestFlight.
4. **GitHub release** — tag `vX.Y.Z` with generated notes.

## After the stores approve
Actions → **Announce update** → type `optional` or `force`. It writes the
version + changelog (from the release's commits, or your text in English and
Arabic) to `app_versions` in the backend; the in-app dialog does the rest.
Credentials: [backend.md](backend.md) → "CI credentials".

## Social posts
`.github/workflows/social.yml` announces updates on LinkedIn, the Facebook
Page, Instagram, YouTube and TikTok through
[3shmawi/social-publisher](https://github.com/3shmawi/social-publisher)
(its README has the step-by-step setup for each platform). A version is
written per platform in English and Arabic, you approve, then each platform
posts on its own; one failing doesn't stop the others.

- **Who writes:** Claude, on your Claude Pro/Max plan, when the
  `CLAUDE_CODE_OAUTH_TOKEN` secret is set (run `claude setup-token` once a
  year; no API credit needed). Without it, fixed templates write the posts
  from `store/android/<lang>/changelogs/default.txt` (keep it filled in for
  each release, in both languages) and the `SOCIAL_HASHTAGS` variable
  (default `Flutter,MobileApps`).

- **When:** after every store release (GitHub Actions: `release.yml` starts
  it, since a release created by the workflow's token starts no other
  workflow; Codemagic: the `v*` tag it pushes), when you publish a GitHub
  Release by hand, every two weeks with the changes since the last post, or
  Actions → **Social posts** → Run workflow.
- **Turn it on:** create the environment **`social`** (Settings →
  Environments) with yourself as required reviewer, add the secrets (table
  below), set the repo variable `SOCIAL_ENABLED=true`, then run it by hand
  with `dry_run` ticked and read the posts in the job summary.
- **Go live:** set `SOCIAL_LIVE=true`. Release and schedule runs then stop at
  **Approve posts**; approve once the version is live in the stores
  (approval waits up to 30 days). Until then they're dry runs.
- **Never twice:** posted updates are tagged `social/posted/<tag>/<platform>`;
  `force` posts again. Internal-only updates (chore, ci, refactor…) and notes
  containing `[skip social]` are skipped.
- **Video:** a `*.mp4` release asset or `marketing/videos/v<version>.mp4`
  (e.g. the Demo video output) goes to YouTube, Facebook, LinkedIn, Instagram
  (a Reel) and TikTok; none → Instagram, YouTube and TikTok are skipped. YouTube keeps API uploads private until the Google Cloud project
  passes YouTube's audit; then set `SOCIAL_YOUTUBE_AUDITED=true` and
  `SOCIAL_YOUTUBE_PRIVACY=public`.
- **Optional variables:** `APP_STORE_URL` (once the app is on the App
  Store), `PLAY_STORE_URL`, `SOCIAL_WEBSITE_URL`, `SOCIAL_LANGUAGES`
  (default `en,ar`), `SOCIAL_LINKEDIN_AS` (`person`, `organization`,
  default `both`), `SOCIAL_PLATFORMS` (default `facebook,instagram,linkedin,youtube,tiktok`),
  `SOCIAL_TIKTOK_TOKEN_REPOS` (below).
- **TikTok:** the video lands in your TikTok **inbox as a draft**; open
  TikTok, add a sound and the suggested caption (in the run summary), post.
  TikTok replaces the refresh token on every run, and the workflow saves the
  new one back to `TIKTOK_REFRESH_TOKEN` with `SOCIAL_SECRETS_TOKEN` (without
  it the TikTok job is skipped). So put `TIKTOK_REFRESH_TOKEN` in
  `shared.env` only for the first `tool/setup_secrets.sh`, then delete its
  value there (an empty value doesn't overwrite the secret). Several apps on
  one TikTok account: set `SOCIAL_TIKTOK_TOKEN_REPOS` to all of them
  (`owner/app1,owner/app2`) in each, and give `SOCIAL_SECRETS_TOKEN` access to
  all of them. Setup: social-publisher README → "3b. TikTok".

## Staging builds
Push to `develop` → `staging.yml`:
- **Android** — signed APK attached to a `staging-…` pre-release (last 3
  kept), and a signed AAB uploaded to the Play track `PLAY_STAGING_TRACK`
  (default `internal`) of the separate staging app `__PACKAGE_ID__.stg`
  (installs next to the store app).
- **iOS** — TestFlight of `__PACKAGE_ID__.stg`.

Uses `ENV_STAGING_JSON` and the same keystore and `PLAY_SERVICE_ACCOUNT_JSON`
as prod. One-time setup for the Play upload:
1. Play Console → **Create app** with package `__PACKAGE_ID__.stg`.
2. Play Console → **Users and permissions** → give the Play service account
   release access to that app too.
3. Upload its first AAB by hand (Google only accepts API uploads after
   that): the first run fails and keeps it as the
   `play-staging-aab-for-manual-upload` artifact → Test and release →
   Internal testing → create release → upload it → roll out. Add your
   testers to the internal testing list.

Without `PLAY_SERVICE_ACCOUNT_JSON` the Play step is skipped (APK only).
`ENABLE_PLAY_STAGING=false` turns it off.

## Backend deploys
Changes under `__BACKEND_DIR__` merged to `main` are deployed by the backend's
workflow; PRs touching it run the access-rules tests first. What is
deployed and the secrets it needs: [backend.md](backend.md) → "Deploys".

## Store listing
Texts and images in `store/`, uploaded by Actions → **Store listing**
(fastlane supply/deliver) — see `store/README.md`.
- **iOS:** the job writes a `Deliverfile` before `fastlane deliver`.
  Without one (and without a `./metadata` folder) deliver asks "Do you want
  to setup deliver?" and crashes in CI. It also passes
  `--ignore_language_directory_validation`, because `store/ios/` holds the
  `screenshots/` folder next to the locale folders.
  `store/ios/review_information/notes.txt` (App Review notes) must be
  filled: deliver reads the version's App Review Information while
  uploading and crashes with "No data" when the version has none; with the
  notes it creates it. Once a version has App Review Information, Apple
  refuses an update without the contact (name, email, phone), so the
  `Deliverfile` sends it from the `APP_REVIEW_*` secrets (read from the
  environment, never written to disk). Without those secrets the notes are
  skipped with a warning and the contact stays as set in App Store Connect.
- **Android:** the edit is saved with `--changes_not_sent_for_review true`
  (changes wait in Play Console → **Publishing overview** → **Send changes
  for review**), so the service account needs no production permission.
  The Play images (feature graphic, icon, tablet screenshots) are uploaded
  when `featureGraphic.png` exists.
- **What's new:** `store/ios/<locale>/release_notes.txt` and
  `store/android/<locale>/changelogs/default.txt` are uploaded too; on Play
  they go on the latest release of `PLAY_TRACK` (default `internal`). A
  track can hold several releases ("More than one release found"), so the
  job first reads the newest version code there
  (`google_play_track_version_codes`) and passes it to supply; it fails with
  a clear error when the track is empty. Run Store listing after the release
  build is on Play. On the App Store, What's new is skipped for the app's
  first version (Apple has no field for it on 1.0).
- **Play service account permissions** (Play Console → Users and
  permissions → the service account → App permissions, for the app and the
  `.stg` app), found with Azm's Store listing on 2026-11-15:
  - Release apps to testing tracks; Manage testing tracks and edit tester
    lists (the release and staging uploads).
  - **Manage store presence** (texts, images).
  - **Edit and delete draft apps**: needed while the app is still a draft
    (never published to production); without it the listing commit fails
    with "The caller does not have permission". It can't publish anything.
    After the first production release, check whether Store presence alone
    is enough and drop it.
  - Not needed: Admin, Release to production, financial data.

## Store requirements (check each year)
| Store | Requirement | Where it's handled |
|---|---|---|
| App Store | Built with **Xcode 26+** / iOS 26 SDK (since 28 Apr 2026) | iOS jobs pick the newest Xcode on the runner, or fail with a clear message |
| Google Play | New apps and updates target **Android 16 (API 36)** (since 31 Aug 2026) | `targetSdk = flutter.targetSdkVersion` (36 in Flutter 3.47) |

Both stores raise these every year (Apple in spring, Google in August).
When a deadline is announced, update this table and the workflows in the
kit, then `scripts/kit_sync.sh` in each app.

## Kit sync
`.github/workflows/kit-sync.yml` runs every Monday (or Actions → Kit sync →
Run workflow) and compares this app with the latest flutter-project-kit
using `scripts/kit_sync.sh` (3-way merge, your changes are kept).

- **With `KIT_SYNC_TOKEN`**: it opens a `chore/kit-sync-…` PR with the
  kit's changes; if some files conflict it is a draft with `<<<<<<<`
  markers to resolve. A newer sync closes an older unmerged one. A kit
  version you closed on purpose is not re-opened.
- **Without it**: it opens (and keeps updating) a "Kit update available"
  issue, and you run `scripts/kit_sync.sh` by hand.

Why a token: GitHub's built-in token cannot change files in
`.github/workflows`, and PRs it opens do not start CI. Create a fine-grained
token for this repo only (Contents, Pull requests, Workflows: read & write),
put it in `KIT_SYNC_TOKEN` in `~/.app-secrets/shared.env` (or
`apps/<repo>/app.env`) and run `tool/setup_secrets.sh`, or
`gh secret set KIT_SYNC_TOKEN`. Also allow Actions to open PRs: repo
Settings → Actions → General → "Allow GitHub Actions to create and approve
pull requests".

Always review the PR: kit changes can add packages or change workflows.

## Crash symbols (Sentry)
Release builds are obfuscated; `scripts/upload_symbols.sh` sends the symbols
to Sentry after the store upload so stack traces stay readable. It never
fails the release: if Sentry rejects the upload, the run shows a **Sentry
symbols** warning with Sentry's error, and the tag and GitHub release still
happen. Commit linking is off (`commits: false` under `sentry:` in
`pubspec.yaml`); turn it on only after connecting the Sentry GitHub
integration.

## Pinned tools
Actions are pinned to commits and kept current by Dependabot. These tools
are pinned by hand — bump them here and in the kit together:

| Tool | Where | Version |
|---|---|---|
| Codemagic CLI (`codemagic-cli-tools`) | iOS release/staging jobs | 0.70.2 |
| fastlane | Store listing | 2.241.2 |
| zizmor | CI `security` job | 1.31.1 |
| gitleaks | CI `security` job | v8.30.1 |
| OSV-Scanner | CI `security` job | v2.7.0 |
| Supabase CLI | Supabase workflows, CI RLS tests | 2.120.0 |
| firebase-tools | Firebase deploy, `firebase/tests` | 15.37.0 |
| EGM plugin (`google/elephant-goldfish-model`) | `.claude/settings.json` (`ref`), design reviews | v0.1.1 |

## One-time setup
- Create the app in Play Console and App Store Connect (bundle id
  `__PACKAGE_ID__`).
- Google Play only accepts API uploads after the **first AAB is uploaded
  manually**. Build it once: `flutter build appbundle __FLAVOR_FLAG__ --dart-define-from-file=env/prod.json`.
- Keep `PLAY_RELEASE_STATUS=draft` until the app has passed its first review,
  then set it to `completed`.
- Secrets: see the section for your CI below.

### GitHub Actions secrets
On your Mac, inside the clone: `tool/setup_secrets.sh` (`--dry-run` first to
preview). Shared values come from `~/.app-secrets/shared.env`; this app's
Android upload keystore is generated once into
`~/.app-secrets/apps/__PROJECT_NAME__/` with a random password and the
alias `<repo>-upload` (not a common word: GitHub stars out a secret's text
in every log) — **back that folder up**, Play needs the same key for every
update. Each upload to GitHub is tried up to 4 times, so a network blip
doesn't stop the run halfway; re-running the script is always safe.

| Secret | Content |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | this app's upload keystore, base64 |
| `ANDROID_KEY_ALIAS`, `ANDROID_STORE_PASSWORD`, `ANDROID_KEY_PASSWORD` | keystore credentials |
| `PLAY_SERVICE_ACCOUNT_JSON` | Google Play service-account JSON |
| `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8_BASE64` | App Store Connect API key |
| `IOS_CERTIFICATE_P12_BASE64`, `IOS_CERTIFICATE_PASSWORD` | your Apple Distribution certificate (.p12) |
| `APPLE_TEAM_ID` | Team ID |
| `ENV_PROD_JSON` | contents of `env/prod.json` (re-upload after changing a key; the release run warns about empty keys — `scripts/check_env.sh`) |
| `KIT_SYNC_TOKEN` | optional, see "Kit sync" below |
| `APP_REVIEW_FIRST_NAME`, `APP_REVIEW_LAST_NAME`, `APP_REVIEW_EMAIL`, `APP_REVIEW_PHONE` | App Review contact for Store listing (phone as `+<country> …`); without them the review notes aren't uploaded |
| `CLAUDE_CODE_OAUTH_TOKEN` | Social posts: Claude writes them on your Pro/Max plan (`claude setup-token`, valid a year); without it, templates write them |
| `FB_PAGE_ID`, `FB_PAGE_TOKEN` | Social posts: Facebook Page (long-lived Page token; for Instagram it also needs `instagram_basic` and `instagram_content_publish`) |
| `IG_USER_ID` | Social posts: Instagram professional account linked to the Page (Reels) |
| `LINKEDIN_TOKEN`, `LINKEDIN_AUTHOR_URN`, `LINKEDIN_ORG_URN` | Social posts: LinkedIn as you and/or the company page |
| `LINKEDIN_CLIENT_ID`, `LINKEDIN_CLIENT_SECRET`, `LINKEDIN_REFRESH_TOKEN` | Social posts: LinkedIn token expiry check and automatic refresh (optional) |
| `YT_CLIENT_ID`, `YT_CLIENT_SECRET`, `YT_REFRESH_TOKEN` | Social posts: YouTube upload |
| `TIKTOK_CLIENT_KEY`, `TIKTOK_CLIENT_SECRET`, `TIKTOK_REFRESH_TOKEN` | Social posts: TikTok inbox draft (the workflow keeps the refresh token current) |
| `SOCIAL_SECRETS_TOKEN` | Social posts: fine-grained GitHub token (app repos, *Secrets: read and write*) that saves TikTok's rotated refresh token |

A store whose secrets are missing is skipped (with a warning), not failed.
iOS signing imports your .p12 and lets App Store Connect create/refresh the
provisioning profile with the API key — no new certificate is created.

Repository variables: `PLAY_TRACK` (default `internal`), `PLAY_RELEASE_STATUS`
(`draft` until the first review, then `completed`), optional
`ENABLE_ANDROID=false` / `ENABLE_IOS=false`, `BUILD_NUMBER_OFFSET`.
Staging (Play): `PLAY_STAGING_TRACK` (default `internal`),
`PLAY_STAGING_RELEASE_STATUS` (default `completed`), `ENABLE_PLAY_STAGING=false`
to skip it.

### Codemagic
Fully automated through the Codemagic API — nothing to click in the UI:
1. Once: connect GitHub to your **personal** Codemagic account and put
   `CODEMAGIC_API_TOKEN` (Settings → Integrations → Codemagic API) in
   `~/.app-secrets/shared.env`. Leave `CODEMAGIC_TEAM_ID` empty: the free
   plan (500 macOS M2 minutes/month) only covers personal accounts.
   Budget: a release (Android + iOS) is roughly 20–35 minutes, a PR check
   5–10, so about 10–15 releases a month fit in the free minutes.
2. Per app: `tool/setup_secrets.sh` adds the repo to Codemagic (if needed) and
   writes the same secrets as above as **secure variables** in the group
   `__PROJECT_NAME___secrets`. Re-running replaces the values.
3. `codemagic.yaml` signs Android from `ANDROID_KEYSTORE_BASE64` and iOS from
   your `.p12` + App Store Connect key (same commands as GitHub Actions),
   uploads to Play (`submit_as_draft: true` until the first review) and to
   App Store Connect, and tags the release with `RELEASE_TOKEN`.

## Android signing locally (optional)
Create `android/key.properties` (git-ignored):
```
storeFile=/absolute/path/upload-keystore.jks
storePassword=…
keyAlias=<the ANDROID_KEY_ALIAS in ~/.app-secrets/apps/__PROJECT_NAME__/app.env>
keyPassword=…
```
Without it, release builds fall back to debug signing.
