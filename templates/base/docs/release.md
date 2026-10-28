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
1. **Checks** — format, analyze, unit/widget tests (+ integration tests on an
   Android emulator for PRs).
2. **Android** — signed release AAB (prod) → Play track `PLAY_TRACK`
   (default `internal`).
3. **iOS** — signing files fetched from App Store Connect with the API key →
   IPA → App Store Connect / TestFlight.
4. **GitHub release** — tag `vX.Y.Z` with generated notes.

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
`~/.app-secrets/apps/__PROJECT_NAME__/` with a random password — **back that
folder up**, Play needs the same key for every update.

| Secret | Content |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | this app's upload keystore, base64 |
| `ANDROID_KEY_ALIAS`, `ANDROID_STORE_PASSWORD`, `ANDROID_KEY_PASSWORD` | keystore credentials |
| `PLAY_SERVICE_ACCOUNT_JSON` | Google Play service-account JSON |
| `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8_BASE64` | App Store Connect API key |
| `IOS_CERTIFICATE_P12_BASE64`, `IOS_CERTIFICATE_PASSWORD` | your Apple Distribution certificate (.p12) |
| `APPLE_TEAM_ID` | Team ID |
| `ENV_PROD_JSON` | contents of `env/prod.json` |

A store whose secrets are missing is skipped (with a warning), not failed.
iOS signing imports your .p12 and lets App Store Connect create/refresh the
provisioning profile with the API key — no new certificate is created.

Repository variables: `PLAY_TRACK` (default `internal`), `PLAY_RELEASE_STATUS`
(`draft` until the first review, then `completed`), optional
`ENABLE_ANDROID=false` / `ENABLE_IOS=false`, `BUILD_NUMBER_OFFSET`.

### Codemagic
Fully automated through the Codemagic API — nothing to click in the UI:
1. Once: connect GitHub to Codemagic (Codemagic → Teams → Integrations →
   GitHub) and put `CODEMAGIC_API_TOKEN` (Teams → Integrations → Codemagic
   API) — and optionally `CODEMAGIC_TEAM_ID` — in `~/.app-secrets/shared.env`.
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
keyAlias=upload
keyPassword=…
```
Without it, release builds fall back to debug signing.
