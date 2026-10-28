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
Run `./scripts/setup_secrets.sh` — it reads `~/.flutter-kit/credentials.env`
and sets:

| Secret | Content |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | upload keystore (.jks), base64 |
| `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` | keystore credentials |
| `PLAY_SERVICE_ACCOUNT_JSON` | Google Play service-account JSON |
| `APP_STORE_CONNECT_ISSUER_ID`, `APP_STORE_CONNECT_KEY_IDENTIFIER` | App Store Connect API key ids |
| `APP_STORE_CONNECT_PRIVATE_KEY` | the `.p8` file content |
| `CERTIFICATE_PRIVATE_KEY` | RSA key used to create/reuse the iOS distribution certificate |
| `ENV_PROD_JSON` | contents of `env/prod.json` |

Repository variables: `PLAY_TRACK`, `PLAY_RELEASE_STATUS`, optional
`ENABLE_ANDROID=false` / `ENABLE_IOS=false`, `BUILD_NUMBER_OFFSET`.

### Codemagic
In Codemagic (Team settings):
- **Integrations → Developer Portal**: App Store Connect API key named
  `__ASC_INTEGRATION__`.
- **Code signing identities → Android keystores**: upload keystore with
  reference `upload_keystore`.
- **Code signing identities → iOS certificates**: distribution certificate
  (or let Codemagic generate one).
- **App → Environment variables**, group `__PROJECT_NAME___secrets`:
  `ENV_PROD_JSON`, `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS` (Play JSON), and
  optionally `GITHUB_TOKEN` (to push release tags).

## Android signing locally (optional)
Create `android/key.properties` (git-ignored):
```
storeFile=/absolute/path/upload-keystore.jks
storePassword=…
keyAlias=upload
keyPassword=…
```
Without it, release builds fall back to debug signing.
