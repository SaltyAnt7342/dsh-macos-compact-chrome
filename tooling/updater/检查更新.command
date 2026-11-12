#!/bin/bash
cd "$(dirname "$0")"
printf '\n=== DSH 紧凑版：检查更新 ===\n\n'
bash ./check-update.sh
printf '\n按回车关闭窗口…'
read -r _
