#!/usr/bin/env bash
# Moves the social-publisher pins in the templates to its newest v* tag:
#   templates/base/.github/workflows/social*.yml   uses: …@<sha> # vX.Y.Z
#   templates/base/docs/release.md                 "pinned to vX.Y.Z"
# and notes it in CHANGELOG.md. Prints "changed=<tag>" or "changed=" to
# $GITHUB_OUTPUT (stdout outside Actions). Run from the kit's root.
#
#   .github/scripts/bump_social_publisher.sh [publisher git URL]
set -euo pipefail
url=${1:-https://github.com/3shmawi/social-publisher.git}
out=${GITHUB_OUTPUT:-/dev/stdout}

# Newest vX.Y.Z tag and the commit it points to (peeled for annotated tags).
refs=$(git ls-remote --tags "$url" 'v*')
latest=$(printf '%s\n' "$refs" | sed -n 's#.*refs/tags/\(v[0-9]*\.[0-9]*\.[0-9]*\)$#\1#p' | sort -V | tail -n 1)
[ -n "$latest" ] || { echo "No vX.Y.Z tag at $url"; exit 1; }
sha=$(printf '%s\n' "$refs" | awk -v t="refs/tags/$latest^{}" '$2 == t { print $1 }')
[ -n "$sha" ] || sha=$(printf '%s\n' "$refs" | awk -v t="refs/tags/$latest" '$2 == t { print $1 }')
printf '%s' "$sha" | grep -qE '^[0-9a-f]{40}$' || { echo "Bad commit for $latest: $sha"; exit 1; }

files=(templates/base/.github/workflows/social*.yml)
current=$(grep -ohE 'social-publisher/\.github/workflows/[a-z-]+\.yml@[0-9a-f]{40} # v[0-9.]+' "${files[@]}" \
  | sed -E 's/.* # //' | sort -V | head -n 1)
echo "social-publisher: templates pin ${current:-nothing}, newest is $latest ($sha)"
if [ "$current" = "$latest" ]; then
  echo "changed=" >> "$out"
  exit 0
fi
# Never move backwards (e.g. a tag deleted upstream).
if [ -n "$current" ] && [ "$(printf '%s\n%s\n' "$current" "$latest" | sort -V | tail -n 1)" != "$latest" ]; then
  echo "Pinned $current is newer than $latest; leaving it."
  echo "changed=" >> "$out"
  exit 0
fi

for f in "${files[@]}"; do
  T_SHA="$sha" T_TAG="$latest" perl -pi -e \
    's#(3shmawi/social-publisher/\.github/workflows/[a-z-]+\.yml)@[0-9a-f]{40} \# v[0-9.]+#$1\@$ENV{T_SHA} \# $ENV{T_TAG}#g' "$f"
done
T_TAG="$latest" perl -pi -e 's#pinned to v[0-9]+\.[0-9]+\.[0-9]+#pinned to $ENV{T_TAG}#g' templates/base/docs/release.md
T_TAG="$latest" perl -0pi -e \
  's/## Unreleased\n\n/## Unreleased\n\n- **social-publisher $ENV{T_TAG}:** the social workflows are pinned to it (weekly automatic bump; apps get it through kit sync).\n/' CHANGELOG.md
echo "changed=$latest" >> "$out"
echo "Pinned the templates to $latest."
