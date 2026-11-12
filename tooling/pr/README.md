# 官方 PR 准备状态

提交目标：`deepseek-ai/deepseek-harness`。

## 已准备

- 源码分支：`dsh-src` 的 `sidebar-compact`（2 个 commit）。
- 补丁系列：`0001-...patch`、`0002-...patch`（基于 `dsh-v0.2.2-rc.1`）。
- PR 正文草稿：`PR.md`；Issue 草稿：`ISSUE.md`。

## 还差三步

1. **GitHub 登录**：本机 `gh` 未登录。运行 `gh auth login`（GitHub.com → HTTPS → Login with a web browser），完成后告诉我。
2. **适配最新 master**：官方 master 已比 `0.2.2-rc.1` 前进，`ui-sidebar` 有 17 个文件变化；直接套补丁会在 `SidebarRoot.tsx`、`index.ts`、`sidebar-root.client.spec.tsx` 冲突。需要先把改动移植到最新 master，再跑测试。
3. **Issue + GUI GIF**：按仓库规则，PR 必须引用同仓库 Issue，且 GUI 变更需要 `record-browser-gif` 录屏；登录后创建 Issue 并补 GIF。

## 待办顺序

1. `gh auth login`
2. `gh repo fork deepseek-ai/deepseek-harness --clone=false`
3. 在最新 master 上移植并跑 `vitest run packages/client/ui-sidebar/tests`、`build:artifacts`、`build:check`
4. `gh issue create` → 取得 Issue 编号 → 填入 `PR.md`
5. 补 GIF → `gh pr create --body-file PR.md`

> 在登录完成前不会向任何远端推送。
