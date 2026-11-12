#!/bin/bash
# Commit tooling changes for the compact project and print the Git report.
# Called by rebuild.sh after a successful build; safe when nothing changed.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=common.sh
source "$HERE/common.sh"

VERSION="${1:-$(json_get baseVersion)}"
if [ ! -d "$PREVIEW/.git" ]; then
  echo "Git: 工具目录还不是 git 仓库，跳过自动提交。"
  bash "$HERE/git-report.sh"
  exit 0
fi

git -C "$PREVIEW" add -A
if git -C "$PREVIEW" diff --cached --quiet; then
  echo "Git: 工具仓库没有新的文件改动。"
else
  git -C "$PREVIEW" -c core.hooksPath=/dev/null commit -m "chore(compact-tooling): update to $VERSION" >/dev/null
  git -C "$PREVIEW" tag -f "tooling-$VERSION" >/dev/null
  echo "Git: 工具仓库已提交 $(git -C "$PREVIEW" rev-parse --short HEAD)，标签 tooling-$VERSION"
fi
bash "$HERE/git-report.sh"
