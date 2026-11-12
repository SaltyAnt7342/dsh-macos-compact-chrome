#!/bin/bash
# Rebuild the compact-sidebar app from a newer official source tag.
# The feature patch is applied to the new tag, the app is built with the
# official brand profile, an unsigned DMG is produced, and the feature is
# committed and tagged in the source clone.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=common.sh
source "$HERE/common.sh"

DRY_RUN=0
FORCE=0
INSTALL=0
for argument in "$@"; do
  case "$argument" in
    --dry-run) DRY_RUN=1 ;;
    --force) FORCE=1 ;;
    --install) INSTALL=1 ;;
    *) echo "未知参数: $argument"; exit 2 ;;
  esac
done

PACKAGE_TARGET="$SRC/apps/desktop/scripts/package-target.ts"
PACK_LOCAL="$SRC/apps/desktop/scripts/pack-local-packages.ts"
BACKUP="$UPDATER/.backup"
SUCCESS=0
PREPARED=0
TARGET_TAG=""

restore_scripts() {
  # Each restore is optional; a missing backup must not fail the EXIT trap.
  if [ -f "$BACKUP/package-target.ts" ]; then cp "$BACKUP/package-target.ts" "$PACKAGE_TARGET"; fi
  if [ -f "$BACKUP/pack-local-packages.ts" ]; then cp "$BACKUP/pack-local-packages.ts" "$PACK_LOCAL"; fi
}

finish() {
  restore_scripts
  if [ "$SUCCESS" = 0 ]; then
    if [ "$PREPARED" = 1 ] && [ -n "$TARGET_TAG" ]; then
      git -C "$SRC" reset --hard "$TARGET_TAG" >/dev/null 2>&1 || true
    fi
    notify "重建失败，详情见 Terminal 输出"
  fi
}
trap finish EXIT

fail() {
  echo
  echo "✗ $*"
  log "rebuild failed: $*"
  exit 1
}

if [ "$DRY_RUN" = 0 ] && [ -n "$(git -C "$SRC" status --porcelain 2>/dev/null)" ]; then
  fail "源码目录有未提交改动，请先处理：$SRC"
fi

echo "→ 获取官方最新 tag…"
git -C "$SRC" fetch --tags "$REPO" >/dev/null 2>&1 || fail "无法 git fetch（检查网络）"
LATEST_TAG="$(latest_tag || true)"
[ -n "$LATEST_TAG" ] || fail "没有取到官方 tag"
VERSION="${LATEST_TAG#dsh-v}"
BASE_VERSION="$(json_get baseVersion)"

if [ "$FORCE" = 0 ] && [ "$(version_gt "$VERSION" "$BASE_VERSION")" != yes ]; then
  echo "✓ 已是最新（紧凑版 ${BASE_VERSION}，官方 ${VERSION}），无需重建。"
  SUCCESS=1
  exit 0
fi

echo "→ 目标版本: ${VERSION}（tag ${LATEST_TAG}）"
if [ "$DRY_RUN" = 1 ]; then
  cat <<EOF
[dry-run] 将要执行：
  git checkout -B compact-$VERSION $LATEST_TAG
  git apply --3way $PATCH
  # 临时切换未签名打包为 official 品牌配置
  pnpm install --frozen-lockfile
  pnpm run package:desktop:mac:arm64:unsigned
  cp <dmg> $PREVIEW/DSH-Compact-$VERSION-arm64.dmg
  git commit / git tag compact-$VERSION
  git diff $LATEST_TAG..HEAD > $PATCH
EOF
  SUCCESS=1
  exit 0
fi

echo "→ 切到新版本工作分支 compact-${VERSION}…"
git -C "$SRC" checkout -B "compact-$VERSION" "$LATEST_TAG" >/dev/null 2>&1 || fail "无法切到 $LATEST_TAG"

echo "→ 套用紧凑侧栏补丁…"
if ! git -C "$SRC" apply --3way "$PATCH"; then
  git -C "$SRC" reset --hard "$LATEST_TAG" >/dev/null 2>&1 || true
  fail "补丁和新版源码冲突，需要人工调整（补丁：${PATCH}）"
fi
TARGET_TAG="$LATEST_TAG"
PREPARED=1

mkdir -p "$BACKUP"
cp "$PACKAGE_TARGET" "$BACKUP/package-target.ts"
cp "$PACK_LOCAL" "$BACKUP/pack-local-packages.ts"

echo "→ 临时切换到 official 品牌构建（重建后自动还原）…"
/usr/bin/python3 - "$PACKAGE_TARGET" "$PACK_LOCAL" <<'PY'
import sys

package_target, pack_local = sys.argv[1], sys.argv[2]
old_build = "invocation.unsigned ? ['run', 'build', '--profile', 'local'] : ['run', 'build:official']"
new_build = "invocation.unsigned ? ['run', 'build', '--profile', 'official'] : ['run', 'build:official']"
text = open(package_target, encoding="utf-8").read()
if old_build not in text:
    raise SystemExit("package-target.ts 的 unsigned 构建行已变化，停止自动重建")
open(package_target, "w", encoding="utf-8").write(text.replace(old_build, new_build, 1))
old_pack = "resolveClientBuildEnvironment(repositoryClientBuildEnvironment(root), 'local')"
new_pack = "resolveClientBuildEnvironment(repositoryClientBuildEnvironment(root), 'official')"
text = open(pack_local, encoding="utf-8").read()
if old_pack not in text:
    raise SystemExit("pack-local-packages.ts 的构建配置行已变化，停止自动重建")
open(pack_local, "w", encoding="utf-8").write(text.replace(old_pack, new_pack, 1))
PY

echo "→ 安装依赖…"
cd "$SRC"
npx -y pnpm@11.28.5 install --frozen-lockfile || fail "pnpm install 失败"

echo "→ 构建并打包（约 5–10 分钟）…"
npx -y pnpm@11.28.5 run package:desktop:mac:arm64:unsigned || fail "打包失败"

DMG="$(find "$SRC/apps/desktop/.desktop-build/targets/mac-arm64/unsigned-artifacts" -maxdepth 1 -name '*.dmg' -print -quit 2>/dev/null)"
[ -n "$DMG" ] || fail "没有找到生成的 DMG"
OUT="$PREVIEW/DSH-Compact-$VERSION-arm64.dmg"
cp "$DMG" "$OUT" || fail "复制 DMG 失败"

restore_scripts
git -C "$SRC" add -A
git -C "$SRC" -c core.hooksPath=/dev/null commit -m "feat(sidebar): compact macOS chrome for $VERSION" >/dev/null || fail "提交失败"
git -C "$SRC" tag -f "compact-$VERSION" >/dev/null
git -C "$SRC" diff "$LATEST_TAG"..HEAD > "$PATCH"

/usr/bin/python3 - "$VERSION_FILE" "$VERSION" "$LATEST_TAG" "$OUT" <<'PY'
import datetime
import json
import sys

path, version, tag, installer = sys.argv[1:5]
data = json.load(open(path, encoding="utf-8"))
data.update(baseVersion=version, baseTag=tag, builtAt=datetime.date.today().isoformat(), installer=installer.split("/")[-1])
json.dump(data, open(path, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
PY

INSTALLED_VERSION="$HOME/Library/Application Support/DSHCompactUpdater/version.json"
if [ -f "$INSTALLED_VERSION" ]; then
  cp "$VERSION_FILE" "$INSTALLED_VERSION"
fi

rm -rf "$SRC/apps/desktop/.desktop-build"
SUCCESS=1
log "rebuild success: $OUT"
if [ -d "$PREVIEW/.git" ]; then
  bash "$HERE/sync-git.sh" "$VERSION" || echo "Git 同步失败，继续安装"
fi
if [ "$INSTALL" = 1 ]; then
  echo "→ 安装并重启紧凑版…"
  bash "$HERE/install-update.sh" --dmg "$OUT" --yes
  notify "已更新并重启到 $VERSION"
  echo
  echo "✓ 已更新并重启：$VERSION"
  exit 0
fi
notify "新版本 $VERSION 已生成"
open -R "$OUT" >/dev/null 2>&1 || true
echo
echo "✓ 新版本已生成：$OUT"
echo "  退出正在运行的紧凑版，双击新 DMG 安装即可。"
