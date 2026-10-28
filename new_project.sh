#!/usr/bin/env bash
# =============================================================================
#  new_project.sh — create a fully configured Flutter project in one command.
#
#  Usage:
#    ./new_project.sh                       # interactive
#    ./new_project.sh --answers my_app.env  # non-interactive (see answers.example.env)
#    ./new_project.sh --help
#
#  Works on macOS (bash 3.2+) and Linux. iOS flavors/signing need macOS.
# =============================================================================
set -euo pipefail

KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES="$KIT_DIR/templates"
KIT_HOME="${FLUTTER_KIT_HOME:-$HOME/.flutter-kit}"
CONFIG_FILE="${FLUTTER_KIT_CONFIG:-$KIT_HOME/kit.conf}"

ANSWERS_FILE=""
SKIP_CHECKS=false
STRICT=false
ASSUME_YES=false

# ----------------------------------------------------------------------------
# Output helpers
# ----------------------------------------------------------------------------
if [ -t 1 ]; then
  C_RESET=$'\033[0m'; C_BOLD=$'\033[1m'; C_DIM=$'\033[2m'
  C_RED=$'\033[31m'; C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'; C_BLUE=$'\033[34m'
else
  C_RESET=""; C_BOLD=""; C_DIM=""; C_RED=""; C_GREEN=""; C_YELLOW=""; C_BLUE=""
fi

step() { printf '\n%s━━ %s%s\n' "$C_BOLD$C_BLUE" "$*" "$C_RESET"; }
info() { printf '%s›%s %s\n' "$C_BLUE" "$C_RESET" "$*"; }
ok()   { printf '%s✓%s %s\n' "$C_GREEN" "$C_RESET" "$*"; }
warn() { printf '%s!%s %s\n' "$C_YELLOW" "$C_RESET" "$*" >&2; WARNINGS="${WARNINGS:-}• $*"$'\n'; }
die()  { printf '%s✗ %s%s\n' "$C_RED" "$*" "$C_RESET" >&2; exit 1; }

usage() {
  cat <<'EOF'
Create a new Flutter project with the standard stack:
flavors, CI/CD to the stores, monitoring, analytics, version-update gate,
localization (ar/en + RTL), theme files, adaptive widgets, go_router deep links,
tests, docs, website (privacy policy + delete account) and CLAUDE.md.

Options:
  --answers FILE   Read answers from FILE instead of asking (see answers.example.env)
  --skip-checks    Skip the final analyze/test run (faster)
  --strict         Fail if analyze or tests fail (used by the kit's own CI)
  --yes            Don't ask for confirmation before generating
  -h, --help       Show this help

Config:   ~/.flutter-kit/kit.conf          (defaults: org, GitHub owner, email…)
Secrets:  ~/.app-secrets/shared.env        (read by the project's tool/setup_secrets.sh)
EOF
}

# ----------------------------------------------------------------------------
# Prompt helpers (an answer already set in the environment is used as-is)
# ----------------------------------------------------------------------------
# ask VAR "Question" "default"
ask() {
  local var=$1 question=$2 default=${3:-} reply current
  eval "current=\${$var:-}"
  if [ -n "$current" ]; then return 0; fi
  if [ -n "$ANSWERS_FILE" ] && [ -n "$default" ]; then
    eval "$var=\$default"; return 0
  fi
  if [ -n "$default" ]; then
    printf '%s?%s %s %s[%s]%s: ' "$C_BOLD" "$C_RESET" "$question" "$C_DIM" "$default" "$C_RESET"
  else
    printf '%s?%s %s: ' "$C_BOLD" "$C_RESET" "$question"
  fi
  IFS= read -r reply || true
  [ -z "$reply" ] && reply=$default
  eval "$var=\$reply"
}

# choose VAR "Question" default_key "key|Label" "key|Label" ...
choose() {
  local var=$1 question=$2 default=$3 current i=1 reply opt key label default_index=1
  shift 3
  eval "current=\${$var:-}"
  if [ -n "$current" ]; then
    for opt in "$@"; do [ "${opt%%|*}" = "$current" ] && return 0; done
    die "Invalid value '$current' for $var. Allowed: $(for o in "$@"; do printf '%s ' "${o%%|*}"; done)"
  fi
  if [ -n "$ANSWERS_FILE" ]; then eval "$var=\$default"; return 0; fi
  printf '%s?%s %s\n' "$C_BOLD" "$C_RESET" "$question"
  for opt in "$@"; do
    key=${opt%%|*}; label=${opt#*|}
    [ "$key" = "$default" ] && default_index=$i
    printf '   %s%d)%s %s\n' "$C_BOLD" "$i" "$C_RESET" "$label"
    i=$((i + 1))
  done
  while :; do
    printf '   choice %s[%d]%s: ' "$C_DIM" "$default_index" "$C_RESET"
    IFS= read -r reply || true
    [ -z "$reply" ] && reply=$default_index
    if [ "$reply" -ge 1 ] 2>/dev/null && [ "$reply" -le $# ]; then
      i=1
      for opt in "$@"; do
        if [ "$i" -eq "$reply" ]; then eval "$var=\${opt%%|*}"; return 0; fi
        i=$((i + 1))
      done
    fi
    printf '   %s\n' "Enter a number between 1 and $#."
  done
}

confirm() { # confirm "Question" (default yes)
  local reply
  if $ASSUME_YES || [ -n "$ANSWERS_FILE" ]; then return 0; fi
  printf '%s?%s %s %s[Y/n]%s: ' "$C_BOLD" "$C_RESET" "$1" "$C_DIM" "$C_RESET"
  IFS= read -r reply || true
  case "$reply" in n|N|no|NO) return 1 ;; *) return 0 ;; esac
}

expand_path() { case "$1" in "~/"*) printf '%s\n' "$HOME/${1#\~/}" ;; *) printf '%s\n' "$1" ;; esac; }

# Flutter/Dart through FVM when available, so every project is pinned to
# FLUTTER_VERSION (written to .fvmrc). Plain flutter/dart otherwise.
USE_FVM=false
fl() {
  if $USE_FVM; then
    if [ -f .fvmrc ]; then fvm flutter "$@"; else fvm spawn "$FLUTTER_VERSION" "$@"; fi
  else
    flutter "$@"
  fi
}
dt() { if $USE_FVM && [ -f .fvmrc ]; then fvm dart "$@"; else dart "$@"; fi; }

# In-place regex edit that behaves the same on macOS and Linux.
perl_edit() { local file=$1; shift; perl -0pi -e "$@" "$file"; }

# ----------------------------------------------------------------------------
# 1. Arguments, config, preflight
# ----------------------------------------------------------------------------
parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --answers) [ $# -ge 2 ] || die "--answers needs a file"; ANSWERS_FILE=$2; shift 2 ;;
      --skip-checks) SKIP_CHECKS=true; shift ;;
      --strict) STRICT=true; shift ;;
      --yes|-y) ASSUME_YES=true; shift ;;
      -h|--help) usage; exit 0 ;;
      *) die "Unknown option: $1 (see --help)" ;;
    esac
  done
}

load_config() {
  if [ -f "$CONFIG_FILE" ]; then
    # shellcheck source=/dev/null
    . "$CONFIG_FILE"
  else
    warn "No config at $CONFIG_FILE — using built-in defaults. Copy kit.conf.example there to set your org, GitHub owner and email."
  fi
  DEFAULT_ORG=${DEFAULT_ORG:-com.mohager}
  FLUTTER_VERSION=${FLUTTER_VERSION:-}
  GITHUB_OWNER=${GITHUB_OWNER:-3shmawi}
  DEVELOPER_NAME=${DEVELOPER_NAME:-Mohamed Ashmawy}
  SUPPORT_EMAIL=${SUPPORT_EMAIL:-3shmawiii@gmail.com}
  APPLE_TEAM_ID=${APPLE_TEAM_ID:-TEAMID}
  CODEMAGIC_ASC_INTEGRATION=${CODEMAGIC_ASC_INTEGRATION:-codemagic}
  DEFAULT_PRIMARY_COLOR=${DEFAULT_PRIMARY_COLOR:-#4F46E5}
  PROJECTS_DIR=$(expand_path "${PROJECTS_DIR:-$PWD}")
  APP_SECRETS_DIR=$(expand_path "${APP_SECRETS_DIR:-$HOME/.app-secrets}")

  if [ -n "$ANSWERS_FILE" ]; then
    [ -f "$ANSWERS_FILE" ] || die "Answers file not found: $ANSWERS_FILE"
    # shellcheck source=/dev/null
    . "$ANSWERS_FILE"
  fi
}

preflight() {
  step "Checking tools"
  local tool
  for tool in git perl; do
    command -v "$tool" >/dev/null 2>&1 || die "'$tool' is required but not installed."
  done
  if command -v fvm >/dev/null 2>&1 && [ "${KIT_USE_FVM:-true}" != false ]; then
    USE_FVM=true
    if [ -z "$FLUTTER_VERSION" ]; then
      FLUTTER_VERSION=$(fvm api releases --filter-channel stable 2>/dev/null \
        | perl -0ne 'print $1 if /"latest"\s*:\s*\{[^}]*?"stable"\s*:\s*"([^"]+)"/s' || true)
    fi
    [ -n "$FLUTTER_VERSION" ] || die "Set FLUTTER_VERSION in kit.conf (e.g. 3.47.8)."
    info "Installing Flutter $FLUTTER_VERSION with FVM (cached after the first time)…"
    fvm install "$FLUTTER_VERSION" --setup >/dev/null 2>&1 || fvm install "$FLUTTER_VERSION" >/dev/null
    ok "FVM → Flutter $FLUTTER_VERSION"
  else
    command -v flutter >/dev/null 2>&1 || die "Install FVM (brew install fvm) or Flutter."
    [ -n "$FLUTTER_VERSION" ] || FLUTTER_VERSION=$(flutter --version 2>/dev/null | sed -n '1s/^Flutter \([^ ]*\).*/\1/p')
    ok "Flutter ${FLUTTER_VERSION:-?} (no FVM — .fvmrc is still written)"
  fi
  ok "git, perl"
  [ -d "$TEMPLATES/base" ] || die "Templates not found in $TEMPLATES"

  HAS_GH=false
  if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    HAS_GH=true; ok "GitHub CLI (logged in)"
  else
    warn "GitHub CLI not installed or not logged in (gh auth login) — repo creation and CI secrets will be skipped."
  fi

  IS_MAC=false
  if [ "$(uname -s)" = "Darwin" ]; then
    IS_MAC=true
    command -v pod >/dev/null 2>&1 || warn "CocoaPods not found (brew install cocoapods)."
  else
    warn "Not on macOS: iOS flavors are configured on Linux only partially. Run on a Mac for full iOS setup."
  fi
}

# ----------------------------------------------------------------------------
# 2. Questions
# ----------------------------------------------------------------------------
collect_answers() {
  step "Project details"
  ask APP_NAME "App display name (e.g. Cafe Menu)"
  [ -n "$APP_NAME" ] || die "App name is required."
  case "$APP_NAME" in *[\'\"\\\$\`]*) die "App name can't contain quotes, backslashes, \$ or backticks." ;; esac

  local suggested
  suggested=$(printf '%s' "$APP_NAME" | tr '[:upper:]' '[:lower:]' | sed -e 's/[^a-z0-9]\{1,\}/_/g' -e 's/^_*//' -e 's/_*$//')
  case "$suggested" in [0-9]*) suggested="app_$suggested" ;; esac
  ask PROJECT_NAME "Dart project name (snake_case)" "$suggested"
  printf '%s' "$PROJECT_NAME" | grep -Eq '^[a-z][a-z0-9_]*$' || die "Project name must be snake_case: lowercase letters, digits, underscores."

  ask PACKAGE_ID "Package name / bundle ID" "$DEFAULT_ORG.$(printf '%s' "$PROJECT_NAME" | tr -d '_')"
  printf '%s' "$PACKAGE_ID" | grep -Eq '^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$' \
    || die "Package ID must look like com.company.app (lowercase, at least two segments)."

  ask DESCRIPTION "One-line description" "$APP_NAME mobile app."
  case "$DESCRIPTION" in *[\"\\\$\`]*) die "Description can't contain double quotes, backslashes, \$ or backticks." ;; esac

  step "Stack"
  choose ENVIRONMENTS "Environments" "full" \
    "full|dev + staging + prod" \
    "staging-prod|staging + prod" \
    "prod|prod only (no flavors)"
  choose ARCHITECTURE "Architecture (decide it in the idea discussion first)" "simple" \
    "simple|Simple clean architecture (data + presentation per feature)" \
    "layered|Layered clean architecture (data + domain + presentation, use cases)"
  choose STATE "State management" "bloc" \
    "bloc|flutter_bloc (Cubit)" \
    "riverpod|Riverpod (Notifier)" \
    "none|None — ChangeNotifier + InheritedNotifier"
  choose MONITORING "Monitoring" "sentry" \
    "sentry|Sentry (crashes + performance) — recommended" \
    "clarity|Microsoft Clarity (sessions + heatmaps)" \
    "none|None for now"
  choose CI "CI/CD provider" "github" \
    "github|GitHub Actions (public repos)" \
    "codemagic|Codemagic (private repos)"

  local default_visibility=public
  [ "$CI" = "codemagic" ] && default_visibility=private
  choose VISIBILITY "Repository visibility" "$default_visibility" \
    "public|Public" \
    "private|Private"

  step "Branding & links"
  ask PRIMARY_COLOR "Primary color (hex)" "$DEFAULT_PRIMARY_COLOR"
  case "$PRIMARY_COLOR" in \#*) ;; *) PRIMARY_COLOR="#$PRIMARY_COLOR" ;; esac
  printf '%s' "$PRIMARY_COLOR" | grep -Eq '^#[0-9A-Fa-f]{6}$' || die "Primary color must be a 6-digit hex like #4F46E5."

  if [ -z "${DEEPLINK_DOMAIN+x}" ]; then
    if [ -n "$ANSWERS_FILE" ]; then DEEPLINK_DOMAIN=""; else
      ask DEEPLINK_DOMAIN "Domain for https deep links / website (empty = skip for now)" "-"
      [ "$DEEPLINK_DOMAIN" = "-" ] && DEEPLINK_DOMAIN=""
    fi
  fi
  DEEPLINK_DOMAIN=$(printf '%s' "$DEEPLINK_DOMAIN" | sed -e 's#^https\{0,1\}://##' -e 's#/.*$##')

  if $HAS_GH; then
    [ -n "$GITHUB_OWNER" ] || GITHUB_OWNER=$(gh api user --jq .login 2>/dev/null || true)
    choose CREATE_REPO "Create the GitHub repo and push now?" "yes" \
      "yes|Yes — create $VISIBILITY repo ${GITHUB_OWNER:-<you>}/$PROJECT_NAME" \
      "no|No — I'll do it later"
  else
    CREATE_REPO=no
  fi

  ask OUTPUT_DIR "Create the project inside" "$PROJECTS_DIR"
  OUTPUT_DIR=$(expand_path "$OUTPUT_DIR")
  PROJECT_DIR="$OUTPUT_DIR/$PROJECT_NAME"
  [ -e "$PROJECT_DIR" ] && die "$PROJECT_DIR already exists."
  return 0
}

# ----------------------------------------------------------------------------
# 3. Derived values (exported as T_* for template tokens __NAME__)
# ----------------------------------------------------------------------------
derive_values() {
  case "$ENVIRONMENTS" in
    full) ENV_LIST="dev staging prod" ;;
    staging-prod) ENV_LIST="staging prod" ;;
    prod) ENV_LIST="prod" ;;
  esac
  DEFAULT_ENV=${ENV_LIST%% *}
  if [ "$ENV_LIST" = "prod" ]; then HAS_FLAVORS=false; else HAS_FLAVORS=true; fi

  if $HAS_FLAVORS; then
    FLAVOR_FLAG="--flavor prod"
    TEST_FLAVOR_FLAG="--flavor $DEFAULT_ENV"
    AAB_PATH="build/app/outputs/bundle/prodRelease/app-prod-release.aab"
  else
    FLAVOR_FLAG=""
    TEST_FLAVOR_FLAG=""
    AAB_PATH="build/app/outputs/bundle/release/app-release.aab"
  fi

  SCHEME=$(printf '%s' "$PROJECT_NAME" | tr -d '_')
  ORG=${PACKAGE_ID%.*}

  case "$ARCHITECTURE" in
    simple)
      ARCH_LABEL="Simple clean architecture (data + presentation per feature)"
      SETTINGS_MODEL_PATH="features/settings/data/app_settings.dart"
      SETTINGS_REPO_PATH="features/settings/data/settings_repository.dart" ;;
    layered)
      ARCH_LABEL="Layered clean architecture (data + domain + presentation, use cases)"
      SETTINGS_MODEL_PATH="features/settings/domain/entities/app_settings.dart"
      SETTINGS_REPO_PATH="features/settings/domain/repositories/settings_repository.dart" ;;
  esac
  case "$STATE" in
    bloc) STATE_LABEL="flutter_bloc (Cubit)" ;;
    riverpod) STATE_LABEL="Riverpod (Notifier)" ;;
    none) STATE_LABEL="None — ChangeNotifier + InheritedNotifier" ;;
  esac
  case "$MONITORING" in
    sentry)
      MONITORING_LABEL="Sentry"
      MON_LI_EN="<li><strong>Sentry</strong> — crash reports and performance diagnostics (device model, OS version, app version, error details).</li>"
      MON_LI_AR="<li><strong>Sentry</strong> — تقارير الأعطال وأداء التطبيق (نوع الجهاز، إصدار النظام، إصدار التطبيق، تفاصيل الخطأ).</li>" ;;
    clarity)
      MONITORING_LABEL="Microsoft Clarity"
      MON_LI_EN="<li><strong>Microsoft Clarity</strong> — anonymous usage sessions and heatmaps to improve the app experience.</li>"
      MON_LI_AR="<li><strong>Microsoft Clarity</strong> — جلسات استخدام مجهولة الهوية وخرائط تفاعل لتحسين تجربة التطبيق.</li>" ;;
    none)
      MONITORING_LABEL="None"; MON_LI_EN=""; MON_LI_AR="" ;;
  esac
  case "$CI" in
    github) CI_LABEL="GitHub Actions" ;;
    codemagic) CI_LABEL="Codemagic" ;;
  esac

  if [ -n "$DEEPLINK_DOMAIN" ]; then
    WEBSITE_URL="https://$DEEPLINK_DOMAIN"
  elif [ "$CI" = "github" ] && [ "$VISIBILITY" = "public" ] && [ -n "$GITHUB_OWNER" ]; then
    WEBSITE_URL="https://$GITHUB_OWNER.github.io/$PROJECT_NAME"
  else
    WEBSITE_URL="(not deployed yet)"
  fi

  local hex=${PRIMARY_COLOR#\#}
  hex=$(printf '%s' "$hex" | tr '[:lower:]' '[:upper:]')

  export T_APP_NAME="$APP_NAME"
  export T_APP_INITIAL; T_APP_INITIAL=$(printf '%s' "$APP_NAME" | cut -c1 | tr '[:lower:]' '[:upper:]')
  export T_PROJECT_NAME="$PROJECT_NAME"
  export T_PACKAGE_ID="$PACKAGE_ID"
  export T_DESCRIPTION="$DESCRIPTION"
  export T_SCHEME="$SCHEME"
  export T_PRIMARY_HEX="#$hex"
  export T_PRIMARY_COLOR_DART="0xFF$hex"
  export T_DEEPLINK_DOMAIN="${DEEPLINK_DOMAIN:-example.com}"
  export T_WEBSITE_URL="$WEBSITE_URL"
  export T_DEVELOPER_NAME="$DEVELOPER_NAME"
  export T_SUPPORT_EMAIL="$SUPPORT_EMAIL"
  export T_GITHUB_OWNER="${GITHUB_OWNER:-your-github-user}"
  export T_APPLE_TEAM_ID="$APPLE_TEAM_ID"
  export T_ASC_INTEGRATION="$CODEMAGIC_ASC_INTEGRATION"
  export T_ENV_LIST="$ENV_LIST"
  export T_ENVS_LABEL; T_ENVS_LABEL=$(printf '%s' "$ENV_LIST" | sed 's/ /, /g')
  export T_DEFAULT_ENV="$DEFAULT_ENV"
  export T_HAS_FLAVORS="$HAS_FLAVORS"
  export T_FLAVOR_FLAG="$FLAVOR_FLAG"
  export T_TEST_FLAVOR_FLAG="$TEST_FLAVOR_FLAG"
  export T_AAB_PATH="$AAB_PATH"
  export T_ARCHITECTURE="$ARCHITECTURE"
  export T_ARCH_LABEL="$ARCH_LABEL"
  export T_STATE="$STATE"
  export T_STATE_LABEL="$STATE_LABEL"
  export T_MONITORING="$MONITORING"
  export T_MONITORING_LABEL="$MONITORING_LABEL"
  export T_MONITORING_LI_EN="$MON_LI_EN"
  export T_MONITORING_LI_AR="$MON_LI_AR"
  export T_CI="$CI"
  export T_CI_LABEL="$CI_LABEL"
  export T_VISIBILITY="$VISIBILITY"
  export T_SETTINGS_MODEL_PATH="$SETTINGS_MODEL_PATH"
  export T_SETTINGS_REPO_PATH="$SETTINGS_REPO_PATH"
  export T_YEAR; T_YEAR=$(date +%Y)
  export T_DATE; T_DATE=$(date +%Y-%m-%d)
}

print_summary() {
  step "Summary"
  cat <<EOF
  App name        $APP_NAME
  Project         $PROJECT_DIR
  Package / ID    $PACKAGE_ID
  Environments    $T_ENVS_LABEL
  Architecture    $ARCHITECTURE
  State           $STATE_LABEL
  Monitoring      $MONITORING_LABEL
  CI/CD           $CI_LABEL ($VISIBILITY repo)
  Primary color   $T_PRIMARY_HEX
  Deep link host  ${DEEPLINK_DOMAIN:-— (custom scheme $SCHEME:// only)}
  GitHub repo     $( [ "$CREATE_REPO" = yes ] && printf '%s' "${GITHUB_OWNER}/$PROJECT_NAME" || printf 'skip')
EOF
  echo
  confirm "Generate the project?" || die "Cancelled."
}

# ----------------------------------------------------------------------------
# 4. Generation
# ----------------------------------------------------------------------------
create_flutter_project() {
  step "Creating Flutter project"
  mkdir -p "$OUTPUT_DIR"
  fl create \
    --org "$ORG" \
    --project-name "$PROJECT_NAME" \
    --description "$DESCRIPTION" \
    --platforms android,ios \
    --empty \
    "$PROJECT_DIR" >/dev/null
  cd "$PROJECT_DIR"
  rm -f test/widget_test.dart
  # Pin the Flutter version for this project (FVM, CI and Codemagic read it).
  printf '{\n  "flutter": "%s"\n}\n' "$FLUTTER_VERSION" > .fvmrc
  if $USE_FVM; then fvm use "$FLUTTER_VERSION" --force --skip-pub-get >/dev/null 2>&1 || true; fi
  ok "flutter create (Flutter $FLUTTER_VERSION pinned in .fvmrc)"
}

set_package_id() {
  step "Setting package name / bundle ID → $PACKAGE_ID"
  local gradle=android/app/build.gradle.kts old_id main_activity old_pkg new_dir
  [ -f "$gradle" ] || die "$gradle not found (expected a Kotlin DSL Android project)."
  old_id=$(perl -ne 'print "$1" if /applicationId\s*=\s*"([^"]+)"/' "$gradle")
  T_OLD="$old_id" T_NEW="$PACKAGE_ID" perl_edit "$gradle" \
    's/(namespace\s*=\s*")\Q$ENV{T_OLD}\E(")/$1$ENV{T_NEW}$2/g; s/(applicationId\s*=\s*")\Q$ENV{T_OLD}\E(")/$1$ENV{T_NEW}$2/g'

  main_activity=$(find android/app/src/main/kotlin -name MainActivity.kt | head -n 1)
  if [ -n "$main_activity" ]; then
    old_pkg=$(perl -ne 'print "$1" if /^package\s+([\w.]+)/' "$main_activity")
    if [ "$old_pkg" != "$PACKAGE_ID" ]; then
      new_dir="android/app/src/main/kotlin/$(printf '%s' "$PACKAGE_ID" | tr '.' '/')"
      mkdir -p "$new_dir"
      T_NEW="$PACKAGE_ID" perl -pe 's/^package\s+[\w.]+/package $ENV{T_NEW}/' "$main_activity" > "$new_dir/MainActivity.kt"
      rm "$main_activity"
      find android/app/src/main/kotlin -type d -empty -delete
    fi
  fi

  local pbx=ios/Runner.xcodeproj/project.pbxproj ios_old
  if [ -f "$pbx" ]; then
    ios_old=$(perl -ne 'if (/PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);/ && $1 !~ /RunnerTests/) { print $1; exit }' "$pbx")
    T_OLD="$ios_old" T_NEW="$PACKAGE_ID" perl_edit "$pbx" \
      's/PRODUCT_BUNDLE_IDENTIFIER = \Q$ENV{T_OLD}\E(\.RunnerTests)?;/PRODUCT_BUNDLE_IDENTIFIER = $ENV{T_NEW}$1;/g'
  fi
  ok "Android: $PACKAGE_ID · iOS: $PACKAGE_ID"
}

add_dependencies() {
  step "Adding packages"
  local deps dev_deps
  deps="go_router flutter_screenutil supabase_flutter posthog_flutter package_info_plus url_launcher shared_preferences"
  dev_deps="very_good_analysis mocktail"
  case "$STATE" in
    bloc) deps="$deps flutter_bloc"; dev_deps="$dev_deps bloc_test" ;;
    riverpod) deps="$deps flutter_riverpod" ;;
  esac
  case "$MONITORING" in
    sentry) deps="$deps sentry_flutter"; dev_deps="$dev_deps sentry_dart_plugin" ;;
    clarity) deps="$deps clarity_flutter" ;;
  esac
  $HAS_FLAVORS && dev_deps="$dev_deps flutter_flavorizr"

  # shellcheck disable=SC2086
  fl pub add 'flutter_localizations:{"sdk":"flutter"}' intl $deps >/dev/null
  # shellcheck disable=SC2086
  fl pub add 'dev:integration_test:{"sdk":"flutter"}' $(printf 'dev:%s ' $dev_deps) >/dev/null

  # Enable l10n code generation.
  perl_edit pubspec.yaml 's/^flutter:[ \t]*\n/flutter:\n  generate: true\n/m'
  # Sentry: upload obfuscation symbols from CI (scripts/upload_symbols.sh).
  if [ "$MONITORING" = sentry ] && ! grep -q '^sentry:' pubspec.yaml; then
    printf '\nsentry:\n  upload_debug_symbols: true\n  upload_sources: true\n  log_level: error\n' >> pubspec.yaml
  fi
  # very_good_analysis replaces flutter_lints.
  grep -q '^  flutter_lints:' pubspec.yaml && fl pub remove flutter_lints >/dev/null
  ok "$(printf '%s' "$deps" | wc -w | tr -d ' ') runtime + $(printf '%s' "$dev_deps" | wc -w | tr -d ' ') dev packages"
}

setup_flavors() {
  $HAS_FLAVORS || { info "Single environment (prod) — no flavors."; return 0; }
  step "Configuring flavors: $T_ENVS_LABEL"
  {
    printf 'app:\n  android:\n    flavorDimensions: "flavor-type"\n\nflavors:\n'
    local env suffix name
    for env in $ENV_LIST; do
      case "$env" in
        dev) suffix=".dev"; name="$APP_NAME Dev" ;;
        staging) suffix=".stg"; name="$APP_NAME Stg" ;;
        prod) suffix=""; name="$APP_NAME" ;;
      esac
      printf '  %s:\n    app:\n      name: "%s"\n    android:\n      applicationId: "%s%s"\n    ios:\n      bundleId: "%s%s"\n' \
        "$env" "$name" "$PACKAGE_ID" "$suffix" "$PACKAGE_ID" "$suffix"
    done
  } > flavorizr.yaml

  if $IS_MAC && ! gem list -i xcodeproj >/dev/null 2>&1; then
    warn "Ruby gem 'xcodeproj' is missing (sudo gem install xcodeproj) — iOS flavors may fail."
  fi
  # flavorizr asks "Do you want to proceed?" and needs a terminal, even in CI:
  # run it in a pseudo-terminal and answer "y" only when that prompt appears.
  local runner="dart"; $USE_FVM && runner="fvm dart"
  local pty_helper; pty_helper=$(mktemp)
  cat > "$pty_helper" <<'PY'
import fcntl, os, pty, select, struct, sys, termios
pid, fd = pty.fork()
if pid == 0:
    # Dart's stdout.hasTerminal is false on a 0x0 terminal: give it a size.
    fcntl.ioctl(sys.stdout.fileno(), termios.TIOCSWINSZ, struct.pack("HHHH", 50, 120, 0, 0))
    os.execvp(sys.argv[1], sys.argv[1:])
fcntl.ioctl(fd, termios.TIOCSWINSZ, struct.pack("HHHH", 50, 120, 0, 0))
tail = b""
while True:
    try:
        ready, _, _ = select.select([fd], [], [], 900)
        if not ready:
            break
        data = os.read(fd, 4096)
    except OSError:
        break
    if not data:
        break
    sys.stdout.buffer.write(data)
    sys.stdout.flush()
    tail = (tail + data)[-300:]
    if b"(Y/n)" in tail or b"(y/N)" in tail:
        os.write(fd, b"y\n")
        tail = b""
_, status = os.waitpid(pid, 0)
sys.exit(os.waitstatus_to_exitcode(status))
PY
  # `dart run` doesn't hand the pty to the tool, so run flavorizr's entrypoint
  # directly; use its --force flag instead when this version has one.
  local help entry
  help=$($runner run flutter_flavorizr --help 2>&1 || true)
  entry=$(python3 -c 'import json,sys,os
cfg=json.load(open(".dart_tool/package_config.json"))
for p in cfg["packages"]:
    if p["name"]=="flutter_flavorizr":
        root=p["rootUri"]
        root=root[7:] if root.startswith("file://") else os.path.normpath(os.path.join(".dart_tool",root))
        print(os.path.join(root,"bin","flutter_flavorizr.dart"))' 2>/dev/null || true)
  {
    echo "== flavorizr --help"; printf '%s\n' "$help"; echo "== entry: $entry"
  } > flavorizr.log
  # shellcheck disable=SC2086
  if printf '%s' "$help" | grep -qE -- '(^|[ ,])--force'; then
    set -- $runner run flutter_flavorizr --force
  elif [ -n "$entry" ] && [ -f "$entry" ]; then
    set -- python3 "$pty_helper" $runner --packages=.dart_tool/package_config.json "$entry"
  else
    set -- python3 "$pty_helper" $runner run flutter_flavorizr
  fi
  local run_log; run_log=$(mktemp)
  local flavorizr_ok=false
  if "$@" >"$run_log" 2>&1 && ! grep -q 'Unhandled exception' "$run_log"; then flavorizr_ok=true; fi
  { echo "== run: $*"; cat "$run_log"; } >> flavorizr.log
  rm -f "$run_log"
  if $flavorizr_ok; then
    ok "flutter_flavorizr (Android + iOS schemes, icons, names, bundle IDs)"
    rm -f flavorizr.log
  else
    warn "flutter_flavorizr failed — see $PROJECT_DIR/flavorizr.log. Fix and re-run: dart run flutter_flavorizr"
    if $STRICT; then tail -n 40 flavorizr.log; die "--strict: flavorizr failed."; fi
  fi
  rm -f "$pty_helper"
  # Flavorizr generates its own Dart entry files; the kit provides its own.
  rm -rf lib/pages lib/app.dart lib/flavors.dart lib/main_*.dart
}

copy_tree() { # copy_tree <template dir> — copies into the project and records files
  local src=$1 rel
  [ -d "$src" ] || die "Missing template folder: $src"
  ( cd "$src" && find . -type f ! -name '.DS_Store' ) | while IFS= read -r rel; do
    rel=${rel#./}
    mkdir -p "$(dirname "$rel")"
    cp "$src/$rel" "$rel"
    printf '%s\n' "$rel" >> "$COPIED_LIST"
  done
}

apply_templates() {
  step "Applying templates"
  COPIED_LIST=$(mktemp)
  copy_tree "$TEMPLATES/base"
  copy_tree "$TEMPLATES/arch/$ARCHITECTURE"
  copy_tree "$TEMPLATES/state/$STATE"
  copy_tree "$TEMPLATES/monitoring/$MONITORING"
  copy_tree "$TEMPLATES/ci/$CI"

  # Replace __TOKEN__ with $T_TOKEN in every copied file.
  local file
  sort -u "$COPIED_LIST" | while IFS= read -r file; do
    perl -pi -e 's/__([A-Z][A-Z0-9_]*?)__/exists $ENV{"T_$1"} ? $ENV{"T_$1"} : "__$1__"/ge' "$file"
  done
  rm -f "$COPIED_LIST"

  # Environment files (real ones are git-ignored).
  local env
  for env in $ENV_LIST; do cp env/example.json "env/$env.json"; done

  write_vscode_launch

  # Project metadata used by scripts/run.sh and scripts/new_feature.sh
  cat > .project-kit.env <<EOF
# Generated by flutter-project-kit on $T_DATE — read by scripts/*.sh
APP_NAME="$APP_NAME"
PROJECT_NAME=$PROJECT_NAME
PACKAGE_ID=$PACKAGE_ID
ENV_LIST="$ENV_LIST"
DEFAULT_ENV=$DEFAULT_ENV
HAS_FLAVORS=$HAS_FLAVORS
ARCHITECTURE=$ARCHITECTURE
STATE=$STATE
MONITORING=$MONITORING
CI=$CI
EOF

  chmod +x scripts/*.sh tool/*.sh tool/*.py .githooks/* 2>/dev/null || true
  [ "$CI" = "codemagic" ] || rm -f tool/codemagic_secrets.py
  ok "Templates applied (base + $ARCHITECTURE + $STATE + $MONITORING + $CI)"
}

write_vscode_launch() {
  mkdir -p .vscode
  local env first=true flavor_args
  {
    printf '{\n  "version": "0.2.0",\n  "configurations": [\n'
    for env in $ENV_LIST; do
      $first || printf ',\n'
      first=false
      flavor_args=""
      $HAS_FLAVORS && flavor_args="\"--flavor\", \"$env\", "
      printf '    {\n      "name": "%s",\n      "request": "launch",\n      "type": "dart",\n      "program": "lib/main.dart",\n      "args": [%s"--dart-define-from-file=env/%s.json"]\n    }' \
        "$APP_NAME ($env)" "$flavor_args" "$env"
    done
    printf '\n  ]\n}\n'
  } > .vscode/launch.json
}

update_gitignore() {
  cat >> .gitignore <<'EOF'

# --- flutter-project-kit ---
# Environment values (only env/example.json is committed)
env/*.json
!env/example.json
# Signing material — never commit
android/key.properties
*.jks
*.keystore
*.p8
*.p12
*.mobileprovision
# Generated
lib/l10n/gen/
coverage/
flavorizr.log
analyze.log
test.log
# FVM (the pinned version lives in .fvmrc, which is committed)
.fvm/
EOF
}

patch_android() {
  step "Patching Android (signing, deep links, PostHog)"
  local gradle=android/app/build.gradle.kts manifest=android/app/src/main/AndroidManifest.xml

  # Release signing from android/key.properties (written by CI, or locally).
  if ! grep -q 'keystoreProperties' "$gradle"; then
    perl_edit "$gradle" 's/\A/import java.io.FileInputStream\nimport java.util.Properties\n\n/'
    perl_edit "$gradle" 's/^android \{/val keystoreProperties = Properties()\nval keystorePropertiesFile = rootProject.file("key.properties")\nif (keystorePropertiesFile.exists()) {\n    keystoreProperties.load(FileInputStream(keystorePropertiesFile))\n}\n\nandroid {/m'
    perl_edit "$gradle" 's/^([ \t]*)buildTypes \{/$1signingConfigs {\n$1    create("release") {\n$1        if (keystorePropertiesFile.exists()) {\n$1            keyAlias = keystoreProperties["keyAlias"] as String\n$1            keyPassword = keystoreProperties["keyPassword"] as String\n$1            storeFile = file(keystoreProperties["storeFile"] as String)\n$1            storePassword = keystoreProperties["storePassword"] as String\n$1        }\n$1    }\n$1}\n\n$1buildTypes {/m'
    perl_edit "$gradle" 's/[ \t]*\/\/ TODO: Add your own signing config[^\n]*\n[ \t]*\/\/ Signing with the debug keys[^\n]*\n//'
    perl_edit "$gradle" 's/signingConfig = signingConfigs\.getByName\("debug"\)/signingConfig = if (keystorePropertiesFile.exists()) {\n                signingConfigs.getByName("release")\n            } else {\n                signingConfigs.getByName("debug")\n            }/'
    grep -q 'signingConfigs.getByName("release")' "$gradle" || warn "Couldn't patch release signing in $gradle — add it manually (see docs/release.md)."
  fi

  # Deep links: custom scheme always, https App Links when a domain is set.
  local filters
  filters="            <intent-filter>
                <action android:name=\"android.intent.action.VIEW\" />
                <category android:name=\"android.intent.category.DEFAULT\" />
                <category android:name=\"android.intent.category.BROWSABLE\" />
                <data android:scheme=\"$SCHEME\" />
            </intent-filter>"
  if [ -n "$DEEPLINK_DOMAIN" ]; then
    filters="$filters
            <intent-filter android:autoVerify=\"true\">
                <action android:name=\"android.intent.action.VIEW\" />
                <category android:name=\"android.intent.category.DEFAULT\" />
                <category android:name=\"android.intent.category.BROWSABLE\" />
                <data android:scheme=\"https\" android:host=\"$DEEPLINK_DOMAIN\" />
            </intent-filter>"
  fi
  T_FILTERS="$filters" perl_edit "$manifest" 's/(\n[ \t]*<\/activity>)/\n$ENV{T_FILTERS}$1/'

  # PostHog is initialised manually from Dart (so keys come from env/*.json).
  T_META='        <meta-data android:name="com.posthog.posthog.AUTO_INIT" android:value="false" />' \
    perl_edit "$manifest" 's/(\n[ \t]*<\/application>)/\n$ENV{T_META}$1/'
  ok "Android patched"
}

plist_add() { # plist_add <plist> <key> <xml value>
  local plist=$1 key=$2 value=$3
  grep -q "<key>$key</key>" "$plist" && return 0
  T_ENTRY="	<key>$key</key>
	$value" perl_edit "$plist" 's/(\n<\/dict>\s*\n<\/plist>)/\n$ENV{T_ENTRY}$1/'
}

patch_ios() {
  step "Patching iOS (deep links, localizations, PostHog, export compliance)"
  local plist=ios/Runner/Info.plist pbx=ios/Runner.xcodeproj/project.pbxproj
  [ -f "$plist" ] || { warn "Info.plist not found — skipping iOS patches."; return 0; }

  plist_add "$plist" "FlutterDeepLinkingEnabled" "<true/>"
  plist_add "$plist" "com.posthog.posthog.AUTO_INIT" "<false/>"
  plist_add "$plist" "ITSAppUsesNonExemptEncryption" "<false/>"
  plist_add "$plist" "CFBundleLocalizations" "<array>
		<string>en</string>
		<string>ar</string>
	</array>"
  plist_add "$plist" "CFBundleURLTypes" "<array>
		<dict>
			<key>CFBundleURLSchemes</key>
			<array>
				<string>$SCHEME</string>
			</array>
		</dict>
	</array>"

  if [ -n "$DEEPLINK_DOMAIN" ]; then
    cat > ios/Runner/Runner.entitlements <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.developer.associated-domains</key>
	<array>
		<string>applinks:$DEEPLINK_DOMAIN</string>
	</array>
</dict>
</plist>
EOF
    if [ -f "$pbx" ] && ! grep -q 'CODE_SIGN_ENTITLEMENTS' "$pbx"; then
      perl_edit "$pbx" 's/^([ \t]*)(PRODUCT_BUNDLE_IDENTIFIER = (?![^;\n]*RunnerTests)[^;\n]*;)/$1CODE_SIGN_ENTITLEMENTS = Runner\/Runner.entitlements;\n$1$2/mg'
    fi
  fi
  ok "iOS patched"
}

verify_project() {
  step "Generating code & verifying"
  fl pub get >/dev/null
  fl gen-l10n >/dev/null
  dt fix --apply >/dev/null 2>&1 || true
  dt format . >/dev/null

  ANALYZE_OK=skipped; TESTS_OK=skipped
  if $SKIP_CHECKS; then info "Checks skipped (--skip-checks)"; return 0; fi
  if fl analyze >analyze.log 2>&1; then ANALYZE_OK=yes; ok "flutter analyze: no issues"; rm -f analyze.log
  else ANALYZE_OK=no; warn "flutter analyze found issues — see $PROJECT_DIR/analyze.log"; fi
  if fl test >test.log 2>&1; then TESTS_OK=yes; ok "flutter test: all passed"; rm -f test.log
  else TESTS_OK=no; warn "Some tests failed — see $PROJECT_DIR/test.log"; fi
  if $STRICT && { [ "$ANALYZE_OK" = no ] || [ "$TESTS_OK" = no ]; }; then
    [ -f analyze.log ] && cat analyze.log
    [ -f test.log ] && tail -n 80 test.log
    die "--strict: analyze/tests failed."
  fi
}

init_git() {
  step "Git"
  git init -q -b main 2>/dev/null || { git init -q; git checkout -q -b main; }
  git config core.hooksPath .githooks
  git add -A
  local identity=""
  if [ -z "$(git config user.email || true)" ]; then
    identity="-c user.name=$DEVELOPER_NAME -c user.email=$SUPPORT_EMAIL"
    warn "git user.email isn't set — first commit authored as $SUPPORT_EMAIL. Run: git config --global user.email you@example.com"
  fi
  # shellcheck disable=SC2086
  git ${identity:+-c "user.name=$DEVELOPER_NAME" -c "user.email=$SUPPORT_EMAIL"} commit -q --no-verify \
    -m "chore: bootstrap project from flutter-project-kit"
  ok "Repository initialised on main (hooks: format + analyze + conventional commits)"
}

setup_github() {
  [ "$CREATE_REPO" = "yes" ] || return 0
  $HAS_GH || { warn "GitHub CLI unavailable — skipping repo creation."; return 0; }
  step "GitHub"
  local repo="$PROJECT_NAME"
  [ -n "$GITHUB_OWNER" ] && repo="$GITHUB_OWNER/$PROJECT_NAME"
  if ! gh repo create "$repo" "--$VISIBILITY" --description "$DESCRIPTION" --source . --remote origin >/dev/null; then
    warn "gh repo create failed — create it manually and push."
    return 0
  fi
  ok "Created $repo"
  gh repo edit "$repo" --enable-squash-merge --enable-merge-commit=false --enable-rebase-merge=false \
    --delete-branch-on-merge --enable-auto-merge >/dev/null 2>&1 || true

  if [ "$CI" = "github" ] && [ "$VISIBILITY" = "public" ]; then
    gh api -X POST "repos/$repo/pages" -f build_type=workflow >/dev/null 2>&1 \
      && ok "GitHub Pages enabled (website/ deploys automatically)" \
      || warn "Couldn't enable GitHub Pages — enable it in Settings → Pages → Source: GitHub Actions."
  fi
  git push -q -u origin main && ok "Pushed main (chore commit — no store release is triggered)"

  # main only changes through PRs whose checks pass (you can still push as
  # admin in an emergency). Free private repos don't support this — skipped.
  local checks='"PR title"'
  [ "$CI" = "github" ] && checks='"Format · analyze · test", "Security scan · secrets · dependencies · database", "PR title"'
  if printf '{"required_status_checks":{"strict":true,"contexts":[%s]},"enforce_admins":false,"required_pull_request_reviews":null,"restrictions":null,"allow_force_pushes":false,"allow_deletions":false,"required_conversation_resolution":true}' "$checks" \
      | gh api -X PUT "repos/$repo/branches/main/protection" --input - >/dev/null 2>&1; then
    ok "Branch protection on main (required checks: $(printf '%s' "$checks" | tr -d '"'))"
  else
    warn "Couldn't protect main (private repos need a paid GitHub plan) — PR checks still run."
  fi

  # Secrets (GitHub secrets, or Codemagic app + variables via its API). Needs
  # your Mac: the app's Android keystore is generated and backed up in
  # ~/.app-secrets/apps/<repo>/ by tool/setup_secrets.sh.
  if [ -f "$APP_SECRETS_DIR/shared.env" ] && command -v keytool >/dev/null 2>&1 && command -v openssl >/dev/null 2>&1; then
    if APP_SECRETS_DIR="$APP_SECRETS_DIR" ./tool/setup_secrets.sh; then SECRETS_DONE=true
    else warn "Some secrets weren't set — re-run tool/setup_secrets.sh"; fi
  fi
}

print_next_steps() {
  step "Done 🎉  $APP_NAME is ready at $PROJECT_DIR"
  [ -n "${WARNINGS:-}" ] && printf '%sWarnings:%s\n%s\n' "$C_YELLOW" "$C_RESET" "$WARNINGS"
  cat <<EOF
Next steps (also in docs/getting_started.md):
  1. cd $PROJECT_DIR
  2. Fill env/*.json (Supabase URL/key, PostHog key, ${MONITORING_LABEL} id).
  3. Supabase → SQL editor → run supabase/migrations/0001_app_versions.sql
  4. Run:  ./scripts/run.sh $DEFAULT_ENV
  5. Stores (first time only): create the app in Play Console + App Store Connect,
     upload the first AAB to Play manually.
EOF
  local where="GitHub secrets"; [ "$CI" = "codemagic" ] && where="Codemagic (adds the app + group ${PROJECT_NAME}_secrets)"
  if [ "${SECRETS_DONE:-false}" != true ]; then
    echo "  6. Secrets (on your Mac, inside the clone): tool/setup_secrets.sh → $where"
    echo "     → generates + backs up this app's keystore in ~/.app-secrets/apps/$PROJECT_NAME."
  else
    echo "  6. Secrets: done → $where (keystore backed up in $APP_SECRETS_DIR/apps/$PROJECT_NAME — keep a backup!)"
  fi
  [ -n "$DEEPLINK_DOMAIN" ] && echo "  7. Deep links: enable Associated Domains for $PACKAGE_ID in the Apple Developer portal and host website/.well-known on https://$DEEPLINK_DOMAIN"
  echo
  echo "From now on: commit with conventional messages (feat:, fix:, …), open a PR, merge → the stores get a new release."
}

main() {
  parse_args "$@"
  load_config
  preflight
  collect_answers
  derive_values
  print_summary
  create_flutter_project
  set_package_id
  add_dependencies
  setup_flavors
  apply_templates
  update_gitignore
  patch_android
  patch_ios
  verify_project
  init_git
  setup_github
  print_next_steps
}

main "$@"
