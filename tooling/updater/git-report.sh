#!/bin/bash
# Print a short, user-visible Git status for the compact project.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=common.sh
source "$HERE/common.sh"

OUT="$UPDATER/git-report.txt"

report_repo() {
  local label="$1" path="$2"
  echo ""
  echo "[$label] $path"
  if [ ! -e "$path/.git" ]; then
    echo "  不是 git 仓库"
    return
  fi
  local branch commit tags dirty
  branch="$(git -C "$path" branch --show-current 2>/dev/null || true)"
  commit="$(git -C "$path" log -1 --format='%h %s' 2>/dev/null || true)"
  tags="$(git -C "$path" tag --points-at HEAD 2>/dev/null | paste -sd ', ' -)"
  dirty="$(git -C "$path" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
  echo "  分支: ${branch:-detached}"
  echo "  提交: ${commit:-无}"
  echo "  标签: ${tags:-无}"
  if [ "$dirty" = "0" ]; then
    echo "  工作区: 干净"
  else
    echo "  工作区: ${dirty} 个未提交改动"
  fi
}

{
  echo "━━ Git 更新结果 ━━"
  report_repo "源码仓库" "$SRC"
  report_repo "工具仓库" "$PREVIEW"
  if [ -e "$WORKSPACE/dsh-pr/.git" ]; then
    report_repo "PR 分支" "$WORKSPACE/dsh-pr"
  fi
} | tee "$OUT"
