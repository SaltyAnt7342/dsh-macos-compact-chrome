#!/bin/bash
# Replace the installed compact app with a freshly built DMG and relaunch it.
# The running app is asked to quit first; the old bundle is backed up and
# restored if the swap fails. The DMG is never downloaded by this script.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=common.sh
source "$HERE/common.sh"

TARGET="$COMPACT_APP"
DMG=""
YES=0
DRY_RUN=0
LAUNCH=1
QUIT=1
MOUNT=""

usage() {
  cat <<'EOF'
用法: install-update.sh [--dmg <path>] [--target <app>] [--yes] [--dry-run] [--no-launch] [--no-quit]

默认使用 dsh-sidebar-preview 下最新的 DSH-Compact-*.dmg，安装到
/Applications/DSH 紧凑版.app，然后重新打开。
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dmg) DMG="$2"; shift 2 ;;
    --target) TARGET="$2"; shift 2 ;;
    --yes) YES=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --no-launch) LAUNCH=0; shift ;;
    --no-quit) QUIT=0; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "未知参数: $1"; usage; exit 2 ;;
  esac
done

fail() {
  echo "✗ $*" >&2
  log "install failed: $*"
  exit 1
}

detach_image() {
  if [ -n "$MOUNT" ] && [ -d "$MOUNT" ]; then
    hdiutil detach "$MOUNT" >/dev/null 2>&1 || true
  fi
}
trap detach_image EXIT

if [ -z "$DMG" ]; then
  DMG="$(ls -t "$PREVIEW"/DSH-Compact-*-arm64.dmg 2>/dev/null | head -n 1 || true)"
fi
[ -n "$DMG" ] && [ -f "$DMG" ] || fail "没有找到可安装的紧凑版 DMG"
TARGET="${TARGET%/}"

CANONICAL=0
[ "$TARGET" = "$COMPACT_APP" ] && CANONICAL=1

# The bundle can be renamed in Finder after it was launched, so the running
# process command line may still carry an older bundle name. Match the exact
# target path as well as any compact bundle path.
compact_running() {
  # Match the main executable only: helpers continue into Frameworks, and the
  # Host child repeats the path as an argument. Try pgrep first, then the
  # process table, because either can miss a non-ASCII bundle path.
  pgrep -f "紧凑版.app/Contents/MacOS/DeepSeek Harness( |$)" >/dev/null 2>&1 && return 0
  /bin/ps -axo command= 2>/dev/null | awk -v executable="$TARGET/Contents/MacOS/DeepSeek Harness" '
    { line = $0
      sub(/^ +/, "", line)
      if (index(line, "紧凑版.app/Contents/MacOS/DeepSeek Harness") == 1) { found = 1 }
      if (index(line, executable) == 1) { found = 1 }
    }
    END { exit found ? 0 : 1 }
  '
}

launch_compact() {
  # Agent shells inherit ELECTRON_RUN_AS_NODE=1 from the desktop Host. Launch
  # the executable directly with that override removed and keep its boot log.
  nohup env -u ELECTRON_RUN_AS_NODE "$TARGET/Contents/MacOS/DeepSeek Harness" \
    > "$UPDATER/launch.log" 2>&1 &
}

echo "→ 挂载更新包…"
MOUNT="$(hdiutil attach -nobrowse -readonly "$DMG" 2>/dev/null | awk -F '\t' 'END { print $NF }')"
[ -n "$MOUNT" ] && [ -d "$MOUNT" ] || fail "无法挂载 DMG：$DMG"
SRC_APP="$(find "$MOUNT" -maxdepth 2 -name '*.app' -print -quit 2>/dev/null)"
[ -n "$SRC_APP" ] || fail "DMG 中没有找到 .app"
SRC_ID="$(defaults read "$SRC_APP/Contents/Info" CFBundleIdentifier 2>/dev/null || true)"
SRC_VERSION="$(defaults read "$SRC_APP/Contents/Info" CFBundleShortVersionString 2>/dev/null || true)"
[ "$SRC_ID" = "com.deepseek.harness" ] || fail "更新包不是紧凑版（bundle id: ${SRC_ID:-unknown}）"
if [ -d "$TARGET" ]; then
  TARGET_ID="$(defaults read "$TARGET/Contents/Info" CFBundleIdentifier 2>/dev/null || true)"
  [ "$TARGET_ID" = "com.deepseek.harness" ] || fail "目标 App 不是紧凑版（bundle id: ${TARGET_ID:-unknown}）"
fi

echo "→ 更新包：$(basename "$DMG")（${SRC_VERSION}）"
echo "→ 安装到：$TARGET"
if [ "$DRY_RUN" = 1 ]; then
  echo "[dry-run] 将关闭旧版（仅限默认安装位置）、备份、替换 App 并重新打开。"
  exit 0
fi

if [ "$CANONICAL" = 1 ] && [ "$YES" = 0 ]; then
  CHOICE="$(osascript -e 'display dialog "将关闭并重新打开紧凑版，当前对话会保存。现在安装吗？" buttons {"取消","现在更新"} default button "取消" with title "安装紧凑版更新" with icon note' 2>/dev/null || true)"
  [[ "$CHOICE" == *"现在更新"* ]] || exit 0
fi

PARENT="$(dirname "$TARGET")"
STAGE="$PARENT/.dsh-compact-new.$$.app"
BACKUP="$PARENT/.dsh-compact-backup.$$.app"
cleanup_leftovers() {
  rm -rf "$STAGE"
}
trap 'detach_image; cleanup_leftovers' EXIT

echo "→ 复制新 App…"
rm -rf "$STAGE"
ditto "$SRC_APP" "$STAGE" || fail "复制新 App 失败"
xattr -dr com.apple.quarantine "$STAGE" 2>/dev/null || true
codesign --verify --deep --strict "$STAGE" >/dev/null 2>&1 \
  || echo "  提示：本地未签名构建的签名校验未通过，通常仍可运行。"

if [ "$CANONICAL" = 1 ] && [ "$QUIT" = 1 ] && compact_running; then
  echo "→ 关闭紧凑版…"
  # Target the bundle by path: the official app shares the same bundle id.
  env -u ELECTRON_RUN_AS_NODE osascript -e "tell application \"$TARGET\" to quit" >/dev/null 2>&1 || true
  for _ in $(seq 1 40); do
    compact_running || break
    sleep 0.5
  done
  if compact_running; then
    /bin/ps -axo pid=,command= | awk -v executable="$TARGET/Contents/MacOS/DeepSeek Harness" '
      index($0, "紧凑版.app/Contents/MacOS/DeepSeek Harness") ||
      index($0, executable) { print $1 }
    ' | xargs kill -TERM 2>/dev/null || true
    sleep 2
  fi
  if compact_running; then
    fail "紧凑版没有退出，请手动退出后重试（已取消安装，旧版未改动）"
  fi
fi

if [ -d "$TARGET" ]; then
  mv "$TARGET" "$BACKUP" || fail "备份旧 App 失败"
fi
if ! mv "$STAGE" "$TARGET"; then
  [ -d "$BACKUP" ] && mv "$BACKUP" "$TARGET" || true
  fail "替换 App 失败，已尝试恢复旧版"
fi
detach_image
log "installed $SRC_VERSION to $TARGET"
echo "✓ 已安装 $SRC_VERSION"

if [ "$CANONICAL" = 1 ] && [ "$LAUNCH" = 1 ]; then
  echo "→ 重新打开紧凑版…"
  launch_compact
  LAUNCHED=0
  for _ in $(seq 1 120); do
    if compact_running; then
      LAUNCHED=1
      break
    fi
    sleep 0.5
  done
  if [ "$LAUNCHED" = 1 ]; then
    rm -rf "$BACKUP"
    echo "→ 已重新打开紧凑版"
  else
    # The swap succeeded and the installed bundle reports the new version, so a
    # launch that cannot be observed is not grounds for discarding it: quitting
    # the app also ends the process that started this installer.
    if [ "$(defaults read "$TARGET/Contents/Info" CFBundleShortVersionString 2>/dev/null)" = "$SRC_VERSION" ]; then
      echo "⚠ 未能确认紧凑版已启动，已保留 $SRC_VERSION；请手动打开一次" >&2
      rm -rf "$BACKUP"
      log "installed $SRC_VERSION (launch unconfirmed)"
      exit 0
    fi
    echo "✗ 新版本未能启动，正在恢复旧版…" >&2
    rm -rf "$TARGET"
    if [ -d "$BACKUP" ]; then
      mv "$BACKUP" "$TARGET"
      launch_compact
    fi
    fail "新版本未能启动，已恢复旧版"
  fi
else
  rm -rf "$BACKUP"
fi
