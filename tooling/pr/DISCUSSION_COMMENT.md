实现已准备好（基于当前 master 移植，分支已推送）：

- Fork 分支：https://github.com/SaltyAnt7342/deepseek-harness/tree/feat/sidebar-compact-macos
- 与 master 的对比：https://github.com/deepseek-ai/deepseek-harness/compare/master...SaltyAnt7342:feat/sidebar-compact-macos
- 验证：`vitest` 115 passed；`test:gui` 13095 passed / 1 skipped；`build:artifacts` + `build:check` passed；oxlint 0 warnings / 0 errors。
- PR 描述（含测试矩阵与 AI Usage）与补丁已准备；GUI 演示 GIF 待补。

我尝试用当前账号 @SaltyAnt7342 开 PR，GitHub 返回 `CreatePullRequest` 权限错误（账号创建于 2026-10-22，可能是新账号或仓库交互限制）。如果维护者可以从上面的 fork 分支直接开 PR，或告知需要什么权限/条件，非常感谢。
