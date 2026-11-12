#!/bin/bash
cd "$(dirname "$0")"
bash ./install-agent.sh
printf '\n按回车关闭窗口…'
read -r _
