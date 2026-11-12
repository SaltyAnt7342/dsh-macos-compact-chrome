#!/bin/bash
# Install a per-user launchd agent that checks for a newer official DSH tag
# once per day (and at login). The agent lives in Application Support so
# macOS privacy does not block access to Documents.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
LABEL="com.saltyant73.dsh-compact-update"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
INSTALL="$HOME/Library/Application Support/DSHCompactUpdater"
UID_VALUE="$(id -u)"

mkdir -p "$HOME/Library/LaunchAgents" "$INSTALL"
cp "$HERE/version.py" "$INSTALL/version.py"
cp "$HERE/version.json" "$INSTALL/version.json"
cp "$HERE/agent-check.sh" "$INSTALL/agent-check.sh"
/usr/bin/python3 - "$INSTALL/agent-check.sh" "$HERE/rebuild.sh" <<'PY'
import sys

path, rebuild = sys.argv[1], sys.argv[2]
text = open(path, encoding="utf-8").read()
if "__REBUILD__" not in text:
    raise SystemExit("agent-check.sh template is missing its rebuild placeholder")
open(path, "w", encoding="utf-8").write(text.replace("__REBUILD__", rebuild))
PY
chmod +x "$INSTALL/agent-check.sh"

cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>$INSTALL/agent-check.sh</string>
  </array>
  <key>EnvironmentVariables</key>
  <dict>
    <key>PATH</key>
    <string>/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/opt/homebrew/bin</string>
  </dict>
  <key>RunAtLoad</key>
  <true/>
  <key>StartInterval</key>
  <integer>86400</integer>
  <key>StandardOutPath</key>
  <string>$INSTALL/launchd.out.log</string>
  <key>StandardErrorPath</key>
  <string>$INSTALL/launchd.err.log</string>
</dict>
</plist>
EOF

launchctl bootout "gui/$UID_VALUE/$LABEL" >/dev/null 2>&1 || true
launchctl bootstrap "gui/$UID_VALUE" "$PLIST"
launchctl kickstart -k "gui/$UID_VALUE/$LABEL" >/dev/null 2>&1 || true

echo "✓ 已安装每日检查（登录时 + 每 24 小时）。"
echo "  安装位置：$INSTALL"
echo "  有新版会弹窗，点“现在重建并重启安装”即可。"
echo "  卸载请双击：卸载每日检查.command"
