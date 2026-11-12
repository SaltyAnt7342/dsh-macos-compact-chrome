#!/bin/bash
cd "$(dirname "$0")"
bash ./uninstall-agent.sh
printf '\n按回车关闭窗口…'
read -r _
