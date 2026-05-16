#!/bin/sh
#
# Decide the next release version from git history + conventional commits.
#
#   BUMP=major  → X+1.0.0            (manual only, via workflow_dispatch)
#   BUMP=auto   → look at commits since the latest vX.Y.Z tag:
#                   any  feat...:   → minor  (X.Y+1.0)
#                   else any fix..: → patch  (X.Y.Z+1)
#                   else            → no release (should_release=false)
#
# Emits to $GITHUB_OUTPUT (or stdout when run locally):
#   should_release=true|false
#   version=X.Y.Z          (only when true)
#   tag=vX.Y.Z             (only when true)

set -eu

bump="${BUMP:-auto}"
out="${GITHUB_OUTPUT:-/dev/stdout}"

last=$(git tag -l 'v*' --sort=-v:refname | head -n1)
[ -n "$last" ] || last="v0.0.0"
ver="${last#v}"
MA="${ver%%.*}"; rest="${ver#*.}"; MI="${rest%%.*}"; PA="${rest##*.}"
case "${MA}${MI}${PA}" in *[!0-9]*) MA=0; MI=0; PA=0 ;; esac

if [ "$bump" = "major" ]; then
    MA=$((MA + 1)); MI=0; PA=0
    reason="manual major"
else
    if [ "$last" = "v0.0.0" ]; then range="HEAD"; else range="${last}..HEAD"; fi
    subjects=$(git log $range --no-merges --format='%s' 2>/dev/null || true)
    if printf '%s\n' "$subjects" | grep -Eq '^feat(\(.+\))?!?:'; then
        MI=$((MI + 1)); PA=0
        reason="feat → minor"
    elif printf '%s\n' "$subjects" | grep -Eq '^fix(\(.+\))?!?:'; then
        PA=$((PA + 1))
        reason="fix → patch"
    else
        echo "should_release=false" >> "$out"
        echo "next-version: no feat/fix commits since ${last} — skipping release" >&2
        exit 0
    fi
fi

next="${MA}.${MI}.${PA}"
{
    echo "should_release=true"
    echo "version=${next}"
    echo "tag=v${next}"
} >> "$out"
echo "next-version: ${last} -> v${next} (${reason})" >&2
