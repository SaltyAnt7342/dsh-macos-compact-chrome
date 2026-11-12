# macOS 桌面端侧栏：紧凑布局与经典布局切换

## Motivation

macOS 桌面端的侧栏顶部固定占用 310px（52px 窗栏 + 48px 品牌行 + 48px 新会话 + 120px 三行面板 + 42px 工作区头），首屏可见会话偏少。希望在保持会话字号、行高与工作区树不变的前提下压缩顶部，并提供一个随时切回经典布局的按钮。

Refs: https://github.com/deepseek-ai/deepseek-harness/discussions/12468（仓库 Issues 已关闭，使用 Ideas Discussion）

## Changes

**Interface changes**
- 新增浏览器本地偏好 `dsh.sidebar.compact-layout`（localStorage，`{ compact: boolean }`，默认 `true`）。
- `SidebarRootInjected` 增加 `setCompactLayout` 回调与 `layoutPreference` hook（包内注入面；未新增公共导出）。
- 新增 `layout.compact`、`layout.switchToClassic`、`layout.switchToCompact` 文案，覆盖 8 个语言字典。

**Behavior changes**
- macOS 桌面展开态默认使用紧凑布局：`sidebar.brand.mark` 与 `sidebar.brand.name` 渲染在 52px 窗栏；单行控制条承载新建会话、面板图标与更多；不再渲染品牌行、新会话胶囊和三行面板。
- 窗栏右侧新增布局切换按钮；经典布局保留原有品牌行、胶囊和面板行。选择跨重启保留。
- 非 macOS 平台保持经典布局；会话行（32px / 14px / 20px）、工作区树、搜索、筛选、新建、底部费用卡与账户区均不变。
- 无 Session 格式、模型输入或持久化数据变化。

## Testing

**Test design**

| 场景 | 修改前 | 修改后 | 覆盖测试 |
|:--|:--|:--|:--|
| macOS 展开态默认 | 品牌行 + 新会话 + 3 行面板 | 窗栏品牌 + 单行控制条 | `sidebar-root.client.spec.tsx` 新增 compact 用例 |
| 切换经典/紧凑 | 无入口 | 窗栏按钮切换，`aria-pressed` 更新 | 同上 |
| 非 macOS | 经典布局 | 不变 | 现有快照与平台用例 |
| 面板入口 | 三行面板 | 单行图标 + 更多 | 现有 panel-list 用例 |
| 文案 | 无 | 8 语言键完整 | `satisfies` 类型约束 |

**Test entries**

- `npx pnpm@11.28.5 exec vitest run packages/client/ui-sidebar/tests` — 115 passed（本地，含 master 移植后新增用例）。
- `npx pnpm@11.28.5 run test:gui` — 744 files, 13095 passed, 1 skipped（本地）。
- `npx pnpm@11.28.5 run build:artifacts` + `run build:check` — passed（本地）。
- `npx pnpm@11.28.5 exec oxlint packages/client/ui-sidebar/src packages/client/ui-sidebar/tests` — 0 warnings / 0 errors。
- 手工：打包版（0.2.2-rc.1）实测紧凑/经典切换、刷新后保持、品牌标与名称正确、macOS 窗栏布局；PR 分支改动以单测/构建验证。

<details>
<summary>Proof</summary>

- 侧栏单测：115 passed。
- GUI 套件：13095 passed / 1 skipped。
- 构建：`build:artifacts` 与 `build:check` 通过。
- 打包版：`DeepSeek Harness.app`（0.2.2-rc.1，未签名）实测。
</details>

> 草稿状态：GUI 演示 GIF 尚未嵌入，当前仓库要求 GUI PR 附带 `record-browser-gif` 录屏，待补后转正式 PR。

## AI Usage

<!-- ai-declaration:start -->
[![AI-DECLARATION: copilot 人工把关](https://img.shields.io/badge/䷼%20AI--DECLARATION-copilot%20人工把关-e5e7eb?labelColor=e5e7eb)](https://ai-declaration.md)
<!-- ai-declaration:end -->

| 阶段 | 级别 | AI 参与度 | 决策记录 |
|:--|:--|--:|:--|
| breakdown 问题拆解 | copilot 人工把关 | 70% | AI 拆解现状与压缩项，用户确认目标与范围 |
| design 方案设计 | pair 人工引导 | 45% | 用户给出参考稿与约束，AI 产出布局、切换与验收方案，用户确认 |
| testing 验收测试 | copilot 人工把关 | 80% | AI 写单测/构建/实测，用户查看效果并确认 |
| implementation 技术实现 | copilot 人工把关 | 85% | AI 完成代码、打包与修复；用户确认最终形态 |
| review 评审处理 | n/a 暂不适用 | — | 尚无评审意见 |
