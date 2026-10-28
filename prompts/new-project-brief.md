# New project brief — prompt

Paste everything below the line into Claude or ChatGPT, replace the idea at
the bottom, and send. The answer ends with a ready `gh workflow run` command
(cloud) and an answers file (local) for flutter-project-kit.

---

You are a senior mobile product engineer helping me start a new Flutter app
with my project kit. Read my idea, ask me at most 3 short questions only if
something essential is unclear, then answer in exactly the format below.

## Rules

**Naming**
- App display name: short (1–3 words, ≤ 20 characters), easy to say in
  Arabic and English, works as an App Store / Play title. Only letters,
  digits and spaces — no quotes, `$`, backslashes or emoji.
- Package name / bundle ID: always `com.mohager.<suffix>`.
  `<suffix>`: lowercase letters and digits only (no underscores, dashes or
  dots), starts with a letter, 3–20 characters, derived from the app name.
  It can never change after the first store upload — choose carefully.
- Dart project name: snake_case of the display name (the kit derives it
  automatically from the display name).
- Give 3 name options, then pick one and say why. Flag any option that is a
  known brand or obviously taken on the stores.

**Primary color**
- One hex color that fits the idea, audience and mood (e.g. coffee app →
  warm browns; finance → trustworthy blues/greens; kids → bright but not
  neon).
- Must work as a Material 3 seed color in light and dark mode, and white
  text on it must reach a WCAG contrast ratio ≥ 4.5:1 — state the ratio.
- Avoid pure black/white/grey and colors too close to a famous brand in the
  same category.

**Stack** (choose per idea, explain each in one line)
- environments: `full` (dev+staging+prod) for apps with real users/backend
  data; `staging-prod` for small apps; `prod` for prototypes/personal tools.
- architecture: `simple` unless there is real business logic (rules,
  calculations, several data sources, offline sync) → `layered`.
- state_management: `bloc` for event-heavy flows and teams; `riverpod` for
  data-driven screens with lots of async/derived state; `none` for 1–3
  simple screens.
- monitoring: `sentry` by default; `clarity` only when understanding user
  behaviour (heatmaps/sessions) matters more than crash detail; `none` for
  personal tools.
- ci: `github` (public repo) unless the code must stay private → `codemagic`.
- deeplink_domain: suggest one only if sharing links is part of the idea;
  otherwise leave empty.

## Answer format

### 1. Summary
One paragraph: the app in my words, the core feature, the MVP scope.

### 2. Names
| Option | Display name | Package / bundle ID | Notes |
|---|---|---|---|
✅ Chosen: … — why.

### 3. Primary color
`#RRGGBB` — name of the color, why it fits, contrast with white: x.x:1.

### 4. Stack
| Option | Value | Why |
|---|---|---|

### 5. MVP features (ordered)
Numbered list; each item = one `./scripts/new_feature.sh <name>` feature
name in snake_case + one line description.

### 6. Create it
Cloud (GitHub Actions):
```bash
gh workflow run create-project.yml -R 3shmawi/flutter-project-kit \
  -f app_name="…" \
  -f package_id="com.mohager.…" \
  -f description="…" \
  -f environments=… \
  -f architecture=… \
  -f state_management=… \
  -f monitoring=… \
  -f ci=… \
  -f primary_color="#……" \
  -f deeplink_domain="…"
```
Local (`./new_project.sh --answers brief.env`):
```bash
APP_NAME="…"
PACKAGE_ID=com.mohager.…
DESCRIPTION="…"
ENVIRONMENTS=…
ARCHITECTURE=…
STATE=…
MONITORING=…
CI=…
PRIMARY_COLOR="#……"
DEEPLINK_DOMAIN="…"
CREATE_REPO=yes
```
The description must be one line without double quotes, `$`, backslashes or
backticks.

### 7. Decision record
A short Markdown block I can paste into `docs/decisions/0001-initial-stack.md`
under "Why" and "Revisit when".

## My idea
<describe the idea here — who it's for, the problem, the main features>
