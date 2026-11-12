#!/bin/bash
# Check whether the official DSH source has a newer release tag than the
# compact build, and offer a rebuild. Terminal mode prompts in-place;
# `--auto` (launchd) shows a dialog.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=common.sh
source "$HERE/common.sh"

MODE="${1:-}"
BASE_VERSION="$(json_get baseVersion)"
BASE_TAG="$(json_get baseTag)"
LATEST_TAG="$(latest_tag || true)"
LATEST_VERSION="${LATEST_TAG#dsh-v}"
OFFICIAL_VERSION="$(defaults read "$OFFICIAL_APP/Contents/Info" CFBundleShortVersionString 2>/dev/null || true)"
REBUILD="$HERE/rebuild.sh"

log "check mode=$MODE base=$BASE_VERSION latest=${LATEST_TAG:-?} official=${OFFICIAL_VERSION:-?}"

if [ -z "$LATEST_TAG" ]; then
  echo "无法获取官方源码版本（检查网络后重试）。"
  exit 20
fi

if [ "$(version_gt "$LATEST_VERSION" "$BASE_VERSION")" = yes ]; then
  MESSAGE="官方源码已有新版本 ${LATEST_VERSION}（当前紧凑版 ${BASE_VERSION}）。要现在重建并重启安装吗？重建约需 5–10 分钟，完成后会自动关闭并重新打开紧凑版。"
  log "update available $LATEST_VERSION"
  if [ "$MODE" = "--auto" ]; then
    if [ -f "$UPDATER/notified.txt" ] && [ "$(cat "$UPDATER/notified.txt")" = "$LATEST_VERSION" ]; then
      exit 0
    fi
    printf '%s\n' "$LATEST_VERSION" > "$UPDATER/notified.txt"
    CHOICE="$(osascript -e "display dialog \"$MESSAGE\" buttons {\"稍后\",\"现在重建\"} default button \"稍后\" with title \"DSH 紧凑版更新\" with icon note" 2>/dev/null || true)"
    if [[ "$CHOICE" == *"现在重建"* ]]; then
      osascript -e "tell application \"Terminal\" to do script \"bash '$REBUILD'\"" >/dev/null 2>&1 || true
      osascript -e 'tell application "Terminal" to activate' >/dev/null 2>&1 || true
    fi
    exit 0
  fi
  printf '%s\n' "$MESSAGE"
  read -r -p "现在重建？[y/N] " ANSWER
  if [[ "$ANSWER" =~ ^[Yy]$ ]]; then
    exec bash "$REBUILD" --install
  fi
  exit 0
fi

if [ -n "$OFFICIAL_VERSION" ] && [ "$(version_gt "$OFFICIAL_VERSION" "$BASE_VERSION")" = yes ]; then
  printf '官方 App 已更新到 %s，但源码 tag 还没发布（最新 tag: %s）。等 tag 发布后再重建。\n' "$OFFICIAL_VERSION" "$LATEST_VERSION"
  log "official newer but no source tag: $OFFICIAL_VERSION"
  exit 0
fi

printf '已是最新：紧凑版 %s，官方源码 %s。\n' "$BASE_VERSION" "$LATEST_VERSION"
log "up to date"
