# flutter-project-kit

Creates a new Flutter app that already follows all the standard rules:
flavors, CI/CD to both stores, monitoring, analytics, a version-update gate,
Arabic/English with RTL, theme files, adaptive widgets, go_router deep links,
tests, docs, a website with privacy policy and delete-account pages, FVM, and
a `CLAUDE.md` so any AI agent understands the project.

**Two ways to create a project**

| | Cloud (recommended) | Local |
|---|---|---|
| How | GitHub → Actions → **Create project** → fill the form | `./new_project.sh` |
| Runs on | GitHub's macOS runner (free for public repos) | your Mac |
| Disk used on your Mac | nothing — `git clone` the result when you want to code | Flutter SDK + project |

The kit also tests itself: **Validate kit** generates four option
combinations with the real Flutter SDK and requires `analyze`, tests and a
debug build (Android + iOS) to pass, on every change and weekly.

---

## 1. One-time setup (≈10 minutes)

```bash
brew install gh fvm && gh auth login
gh repo clone 3shmawi/flutter-project-kit ~/dev/flutter-project-kit
cd ~/dev/flutter-project-kit
./setup_kit_repo.sh     # 1st run creates ~/.flutter-kit/kit.conf → fill it, run again
```

`setup_kit_repo.sh` copies your defaults (org, owner, email, Team ID,
`FLUTTER_VERSION`) into the kit repo's variables and stores `KIT_GH_TOKEN`
(classic token: `repo` + `workflow`) so the cloud workflow can create repos.

Store credentials stay in your existing `~/.app-secrets/` (your
`shared.env`). For Codemagic projects also add `CODEMAGIC_API_TOKEN`
(personal account → Settings → Integrations → Codemagic API — no team, so
the free 500 macOS M2 minutes apply) and connect GitHub to Codemagic once — `tool/setup_secrets.sh` then adds the app to Codemagic and
uploads the same secrets as secure variables through the API, so a private
project needs no clicks in the Codemagic UI either. Every generated project ships your `tool/setup_secrets.sh`,
which creates that app's Android keystore and uploads all release secrets.

## 2. Create a project

1. Paste `prompts/new-project-brief.md` + your idea into Claude/ChatGPT. It
   proposes the name, `com.mohager.<app>` package ID, primary color and stack,
   and ends with the exact command to run.
2. **Cloud**: Actions → *Create project* → Run workflow, or
   ```bash
   gh workflow run create-project.yml -R <you>/flutter-project-kit \
     -f app_name="Cafe Menu" -f state_management=riverpod -f architecture=simple
   ```
   ~10 minutes later the new repo exists with code, CI and Pages; the
   run summary shows the link and the next steps.
   **Local**: `./new_project.sh` (interactive) or
   `./new_project.sh --answers answers.example.env`.

| Option | Values |
|---|---|
| Environments | `full` (dev+staging+prod) · `staging-prod` · `prod` |
| Architecture | `simple` · `layered` (with use cases) |
| State management | `bloc` · `riverpod` · `none` |
| Monitoring | `sentry` · `clarity` · `none` |
| CI/CD | `github` (public repo) · `codemagic` (private repo) |
| Brand | `"#RRGGBB, Latin font, Arabic font"` (Google Fonts, bundled offline) |
| Deep-link domain, package ID, description | free text |

3. Then (also in the project's `docs/getting_started.md`):
   - `gh repo clone <you>/<app> && cd <app> && tool/setup_secrets.sh`
     (creates + backs up the app keystore, uploads all store secrets — no
     Flutter needed for this step)
   - fill `env/*.json` (Supabase, PostHog, Sentry/Clarity), then re-run
     `tool/setup_secrets.sh` to upload `ENV_PROD_JSON`
   - run `supabase/migrations/0001_app_versions.sql` in Supabase
   - create the app in Play Console + App Store Connect; upload the first AAB
     to Play manually (Google requires it once)

## 3. Working on a project

```bash
gh repo clone <you>/cafe_menu && cd cafe_menu
fvm install                                 # the version in .fvmrc
git config core.hooksPath .githooks         # format + analyze + commit-message hooks
./scripts/run.sh dev
./scripts/new_feature.sh menu_search        # folders + doc + test folders
git commit -m "feat(search): suggest drinks from favorites"
gh pr create --fill                         # CI: format, analyze, tests, integration tests
# squash-merge → version bump → Play internal + TestFlight + GitHub release
```

| Commit type | Release |
|---|---|
| `feat:` | minor |
| `fix:` `perf:` `refactor:` … | patch |
| `feat!:` / `BREAKING CHANGE:` | major |
| only `docs:` `chore:` `ci:` `test:` `style:` | none |

Show users an update: edit the `app_versions` row in Supabase
(`latest_version` → optional, `min_supported_version` → forced).

**Saving disk space with FVM:** every project points at a shared cached SDK
(`~/fvm/versions/<version>`), so ten projects on the same version use one
SDK. Remove old ones with `fvm remove <version>`; clear Xcode builds with
`rm -rf ~/Library/Developer/Xcode/DerivedData`.

## 4. What a generated project contains

```
CLAUDE.md                     rules + stack for humans and AI agents
.fvmrc                        pinned Flutter version
lib/core/                     config, theme, adaptive, router, update gate,
                              analytics, feature flags, backend, monitoring, di
lib/features/home|settings    example features in your architecture + state choice
lib/l10n/                     app_en.arb, app_ar.arb
test/, integration_test/      unit, widget and integration tests
docs/                         getting started, release, deep links, features, decisions
website/                      landing, privacy, terms, delete account (+ .well-known)
scripts/                      run, new_feature, next_version
tool/setup_secrets.sh         your secrets script (+ ENV_PROD_JSON, Play variables)
.github/workflows/ or codemagic.yaml
.githooks/                    pre-commit (format + analyze), commit-msg (conventional)
supabase/migrations/          app_versions table for the update gate
```

## 5. What runs automatically in every project

| When | What |
|---|---|
| Every PR | format · analyze · unit/widget/security/a11y tests · coverage ≥ 60% · gitleaks · OSV · RLS tests (if `supabase/` changed) · PR-title check · Android emulator integration tests |
| Push to `develop` | staging builds → TestFlight (staging app) + APK pre-release |
| Merge to `main` | version from commits → obfuscated builds → Play + App Store Connect → symbols to Sentry → GitHub release with notes · `supabase/` changes deployed |
| Weekly | Dependabot PRs (patch/minor auto-merge after CI) |
| Every 3 days | Supabase keep-alive |
| PR labelled `demo` | records the feature's integration test → 1080×1920 social video + caption, linked on the PR |
| You click | **Announce update** (in-app optional/force update) · **Store listing** (texts + screenshots) |

Keeping old projects current: `scripts/kit_sync.sh` inside a project
renders the kit's templates at the project's kit version and at the latest,
and 3-way merges the difference on a new branch (`--dry-run` to preview).

## 6. Changing the kit

Everything generated comes from `templates/`:

```
templates/base/                       always copied
templates/arch/{simple,layered}/
templates/state/{bloc,riverpod,none}/
templates/monitoring/{sentry,clarity,none}/
templates/ci/{github,codemagic}/
```

`__TOKEN__` placeholders are replaced from the answers (`derive_values` in
`new_project.sh` lists them). Open a PR on the kit → *Validate kit* proves
every combination still compiles and passes before you merge.

To upgrade Flutter for new projects: change `FLUTTER_VERSION` in
`~/.flutter-kit/kit.conf`, run `./setup_kit_repo.sh`, and let *Validate kit*
confirm it.

## Notes

- iOS flavors and signing need macOS (the cloud workflow uses a macOS runner).
- GitHub Pages needs a public repo on the free plan; for private repos host
  `website/` on Vercel/Netlify or your domain.
- https deep links need a domain you control (`.well-known` files at its root)
  and Associated Domains enabled for the App ID.
- Keep the kit repo public for free macOS minutes; it contains only
  templates — your values live in encrypted secrets/variables.
