#!/bin/bash
cd "$(dirname "$0")"
printf '\n=== DSH 紧凑版：重建并重启（约 5–10 分钟）===\n'
printf '请保持网络连接；构建完成后会自动关闭并重启紧凑版。\n\n'
bash ./rebuild.sh --install
printf '\n按回车关闭窗口…'
read -r _
