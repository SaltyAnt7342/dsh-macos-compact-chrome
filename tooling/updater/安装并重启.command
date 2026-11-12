#!/bin/bash
cd "$(dirname "$0")"
printf '\n=== DSH 紧凑版：安装最新包并重启 ===\n\n'
bash ./install-update.sh
printf '\n按回车关闭窗口…'
read -r _
