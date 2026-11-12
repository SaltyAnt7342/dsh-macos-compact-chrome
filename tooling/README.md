# 源码版构建与更新（tooling）

本目录保存**源码级**紧凑侧栏的补丁、构建与自动更新工具。

和仓库根目录的插件不同：

- 根目录插件（`client.js`）是纯浏览器侧样式插件，装在官方 App 上即可，不需要构建。
- 本目录的补丁会改动 `ui-sidebar` 源码，需要重新打包整个 App，产出本地未签名 DMG 并替换安装。

两者可以同时存在；只想要效果的用户装根目录插件就够了，想改源码再按本文重建。

## 目录

- `dsh-sidebar-compact.patch` —— 应用在对应官方 `dsh-v*` 标签上的侧栏补丁。
- `updater/` —— 每日检查、重建、DMG 安装与 Git 版本记录脚本。
- `pr/` —— 提交给上游的 PR / Issue 草稿与补丁系列。

## 环境要求

构建需要一个工作区，内含官方源码克隆 `dsh-src`，默认布局：

```text
<workdir>/
├── dsh-src/                 # git clone deepseek-ai/deepseek-harness
└── dsh-sidebar-preview/     # 构建输出、DMG、日志
```

脚本从自身位置向上两级推断该工作区；布局不同时显式指定：

```sh
DSH_COMPACT_WORKSPACE=/path/to/workdir bash updater/rebuild.sh --install
```

只改输出目录用 `DSH_COMPACT_OUTPUT_DIR`。

## 常用操作

```sh
# 检查是否有新的官方版本
bash updater/check-update.sh

# 按最新官方标签重建，然后替换安装并重启
bash updater/rebuild.sh --install

# 预览重建会做什么
bash updater/rebuild.sh --dry-run

# 安装已经生成的 DMG
bash updater/install-update.sh --dmg /path/to/DSH-Compact-<版本>-arm64.dmg
```

macOS 上也可以直接双击 `updater/` 里的 `.command` 文件。

## 它怎么工作

1. `git ls-remote` 读官方最新 `dsh-v*` 标签，与 `updater/version.json` 的 `baseVersion` 比较。
2. 切到该标签，应用 `dsh-sidebar-compact.patch`，临时把未签名打包切到 official 品牌配置。
3. `pnpm install` + 打包，产出 arm64 DMG，还原构建脚本，提交并打 `compact-<版本>` 标签，回写补丁。
4. 挂载 DMG，复制新 App 到临时目录，关闭紧凑版，备份并替换，然后重新打开；失败则回滚旧版。

## 注意

- 补丁与新版本源码冲突时脚本会停下，需要人工合并；`0.2.2-rc.2` 就是手工合并了 3 处冲突。
- 构建产物未签名、未公证。
- 紧凑版与官方版共用 `~/.dsh`，不要同时运行；也不要让紧凑版自动更新，否则会覆盖改动。
- 每日检查会写入 `~/Library/LaunchAgents/com.saltyant73.dsh-compact-update.plist`，用 `updater/uninstall-agent.sh` 移除。

## 版本

当前基线 `dsh-v0.2.2-rc.2`，见 [../CHANGELOG.md](../CHANGELOG.md)。
