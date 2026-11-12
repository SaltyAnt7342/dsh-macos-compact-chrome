#!/bin/bash
# Standalone daily check used by the launchd agent. Installed outside
# ~/Documents so macOS privacy (TCC) does not block the agent.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
VERSION_FILE="$HERE/version.json"
REBUILD="__REBUILD__"
REPO="https://github.com/deepseek-ai/deepseek-harness.git"
OFFICIAL_APP="/Applications/DeepSeek Harness.app"
LOG_FILE="$HERE/update.log"

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE"
}

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
    | /usr/bin/python3 "$HERE/version.py" latest
}

version_gt() {
  /usr/bin/python3 "$HERE/version.py" gt "$1" "$2"
}

BASE_VERSION="$(json_get baseVersion)"
LATEST_TAG="$(latest_tag || true)"
LATEST_VERSION="${LATEST_TAG#dsh-v}"
log "agent check base=$BASE_VERSION latest=${LATEST_TAG:-?}"

[ -n "$LATEST_TAG" ] || exit 0
[ "$(version_gt "$LATEST_VERSION" "$BASE_VERSION")" = yes ] || exit 0

if [ -f "$HERE/notified.txt" ] && [ "$(cat "$HERE/notified.txt")" = "$LATEST_VERSION" ]; then
  exit 0
fi
printf '%s\n' "$LATEST_VERSION" > "$HERE/notified.txt"

MESSAGE="官方源码已有新版本 ${LATEST_VERSION}（当前紧凑版 ${BASE_VERSION}）。要现在重建并重启安装吗？重建约需 5–10 分钟，完成后会自动关闭并重新打开紧凑版。"
CHOICE="$(osascript -e "display dialog \"$MESSAGE\" buttons {\"稍后\",\"现在重建\"} default button \"稍后\" with title \"DSH 紧凑版更新\" with icon note" 2>/dev/null || true)"
if [[ "$CHOICE" == *"现在重建"* ]]; then
  osascript -e "tell application \"Terminal\" to do script \"bash '$REBUILD' --install\"" >/dev/null 2>&1 || true
  osascript -e 'tell application "Terminal" to activate' >/dev/null 2>&1 || true
elif [ -z "$CHOICE" ]; then
  osascript -e "display notification \"发现新版本 ${LATEST_VERSION}，请打开 DSH 更新工具\" with title \"DSH 紧凑版\"" >/dev/null 2>&1 || true
fi
