#!/bin/bash
# Remove the per-user update-check agent and its installed helper files.
set -euo pipefail
LABEL="com.saltyant73.dsh-compact-update"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
INSTALL="$HOME/Library/Application Support/DSHCompactUpdater"
launchctl bootout "gui/$(id -u)/$LABEL" >/dev/null 2>&1 || true
rm -f "$PLIST"
rm -rf "$INSTALL"
echo "✓ 已卸载每日检查。"
