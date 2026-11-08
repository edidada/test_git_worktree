# test_git_worktree

一个用于演示 **`git worktree` 工业级用法**的最小仓库（Git 2.56 / Git Bash 实机验证）。

- 完整指南：[docs/git-worktree-industrial-guide.md](docs/git-worktree-industrial-guide.md)
- 一键复现演示：`bash scripts/demo-worktree.sh`
- 搭建 bare 中枢拓扑：`scripts/setup-bare-worktrees.sh`（Bash）/ `scripts/setup-bare-worktrees.ps1`（PowerShell）

## 核心结论

`git worktree` 让**同一个 `.git` 对象库**挂载多个独立工作目录，每个目录绑定一个分支。
工业界最先进的用法是把它固化为仓库拓扑：**bare 对象库作中枢 + 每个长期分支 / 每个并发任务一个 worktree**，
并以此支撑并行 AI Agent、线上热修复零上下文切换、PR 评审与 CI 并发构建。

> 注意：worktree 的目录与 `.git/worktrees/` 元数据**不会被 commit 或 push**，
> 所以拓扑必须靠仓库里的脚本重建 —— 这也是本仓库把 `scripts/` 一起提交的原因。

## 远端

<https://github.com/edidada/test_git_worktree>

## 演示后保留的分支

| 分支 | 含义 |
| --- | --- |
| `main` | 发布基线（已合入 `hotfix/1.0.1`） |
| `develop` | 常驻集成分支 |
| `feature/parallel-agents` | 并行任务 / Agent 工位 A |
| `feature/billing` | 并行任务 / Agent 工位 B |
| `hotfix/1.0.1` | 紧急修复线（含 tag `v1.0.1`） |
