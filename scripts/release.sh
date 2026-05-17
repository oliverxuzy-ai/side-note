#!/bin/sh
#
# LOCAL .dmg build helper: bump VERSION, sync project, build a signed-to-run
# .dmg (route A ad-hoc, per HANDOFF), and create the annotated git tag — all
# on your machine, for testing the packaged app.
#
# Usage:
#   scripts/release.sh patch      # 0.1.0 -> 0.1.1
#   scripts/release.sh minor      # 0.1.0 -> 0.2.0
#   scripts/release.sh major      # 0.1.0 -> 1.0.0
#   scripts/release.sh 0.4.2      # explicit version
#
# NOTE: production releases are now automatic — every push to main runs
# .github/workflows/release.yml, which derives the version from commits
# (feat → minor, fix → patch; major is manual via "Run workflow") and
# publishes a PUBLIC release with the .dmg. You normally do NOT need this
# script; it's only for building/inspecting a .dmg locally. It does not push.

set -eu

repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"

[ $# -eq 1 ] || { echo "usage: scripts/release.sh <patch|minor|major|X.Y.Z>" >&2; exit 1; }

cur=$(tr -d ' \t\n\r' < VERSION)
case "$1" in
  major|minor|patch)
    IFS=. read -r MA MI PA <<EOF
$cur
EOF
    case "$1" in
      major) MA=$((MA + 1)); MI=0; PA=0 ;;
      minor) MI=$((MI + 1)); PA=0 ;;
      patch) PA=$((PA + 1)) ;;
    esac
    next="${MA}.${MI}.${PA}"
    ;;
  [0-9]*.[0-9]*.[0-9]*) next="$1" ;;
  *) echo "release: bad argument '$1'" >&2; exit 1 ;;
esac

echo "release: $cur -> $next"
printf '%s\n' "$next" > VERSION
sh scripts/sync-version.sh

command -v xcodegen   >/dev/null || { echo "release: xcodegen not installed (brew install xcodegen)" >&2; exit 1; }
command -v create-dmg >/dev/null || { echo "release: create-dmg not installed (brew install create-dmg)" >&2; exit 1; }

xcodegen generate

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
archive="$work/SideNote.xcarchive"

xcodebuild -project SideNote.xcodeproj -scheme SideNote \
  -configuration Release -archivePath "$archive" archive

app="$archive/Products/Applications/HoverNote.app"
[ -d "$app" ] || { echo "release: archive produced no HoverNote.app" >&2; exit 1; }

# Stale mount guard (zsh aborts && chains on no-glob-match; test explicitly)
if [ -d "/Volumes/HoverNote" ]; then hdiutil detach "/Volumes/HoverNote" -quiet || true; fi

dmg="HoverNote-${next}.dmg"
rm -f "$dmg"
create-dmg \
  --volname "HoverNote" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "HoverNote.app" 175 200 \
  --hide-extension "HoverNote.app" \
  --app-drop-link 425 200 \
  "$dmg" "$app"

git add VERSION project.yml
git commit -m "chore: release v${next}"
git tag -a "v${next}" -m "HoverNote v${next}"

echo
echo "release: built $dmg and tagged v${next}"
echo "next:    git push && git push origin v${next}"
echo "         (the release workflow attaches the .dmg to a DRAFT release;"
echo "          you review + publish)"
