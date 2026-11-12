#!/bin/bash
# Shared paths and helpers for the DSH compact-sidebar updater.
#
# The tooling directory holds the patch and the built DMG. The build workspace
# must hold the official source clone; set DSH_COMPACT_WORKSPACE when the
# layout differs from <workspace>/{dsh-src,dsh-sidebar-preview}.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UPDATER="$HERE"
TOOLING="$(cd "$HERE/.." && pwd)"

if [ -n "${DSH_COMPACT_WORKSPACE:-}" ]; then
  WORKSPACE="$DSH_COMPACT_WORKSPACE"
else
  CANDIDATE="$(cd "$TOOLING/../.." && pwd)"
  if [ -d "$CANDIDATE/dsh-src" ]; then
    WORKSPACE="$CANDIDATE"
  else
    WORKSPACE="$HOME/Documents/deepseek-harness/default-workspace"
  fi
fi

SRC="$WORKSPACE/dsh-src"
PREVIEW="${DSH_COMPACT_OUTPUT_DIR:-$WORKSPACE/dsh-sidebar-preview}"
PATCH="$TOOLING/dsh-sidebar-compact.patch"
[ -f "$PATCH" ] || PATCH="$PREVIEW/dsh-sidebar-compact.patch"
VERSION_FILE="$UPDATER/version.json"
REPO="https://github.com/deepseek-ai/deepseek-harness.git"
OFFICIAL_APP="/Applications/DeepSeek Harness.app"
# The compact bundle was renamed in Finder on 2026-11-09; keep working under
# whichever of the two names is actually installed.
COMPACT_APP="/Applications/DSH 紧凑版.app"
[ -d "$COMPACT_APP" ] || COMPACT_APP="/Applications/DeepSeek Harness 紧凑版.app"
LOG_FILE="$UPDATER/update.log"

json_get() {
  /usr/bin/python3 - "$VERSION_FILE" "$1" <<'PY'
import json
import sys

print(json.load(open(sys.argv[1], encoding="utf-8")).get(sys.argv[2], ""))
PY
}

latest_tag() {
  git ls-remote --tags "$REPO" 'refs/tags/dsh-v*' 2>/dev/null \
    | sed 's#.*refs/tags/##; s/\^{}$//' \
    | /usr/bin/python3 "$UPDATER/version.py" latest
}

version_gt() {
  /usr/bin/python3 "$UPDATER/version.py" gt "$1" "$2"
}

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE"
}

notify() {
  osascript -e "display notification \"$1\" with title \"DSH 紧凑版\"" >/dev/null 2>&1 || true
}
