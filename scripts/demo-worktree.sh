#!/usr/bin/env bash
# 实机演示：git worktree 工业工作流
# 用法：在仓库根目录执行 `bash scripts/demo-worktree.sh`
# 工位统一放在仓库的同级目录 <repo>_wt/ 下，不污染版本库。
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
REPO="$(basename "$ROOT")"
WT_ROOT="$(dirname "$ROOT")/${REPO}_wt"

echo "主工作区 : $ROOT"
echo "工位容器 : $WT_ROOT"
mkdir -p "$WT_ROOT"

step() { echo; echo "=== $* ==="; }

add_wt() { # <目录名> <分支> <基线>
  local name="$1" branch="$2" base="$3" dir="$WT_ROOT/$1"
  if [ -d "$dir" ]; then
    echo "  [skip] 已存在: $dir"
    return 0
  fi
  if git show-ref -q --verify "refs/heads/$branch"; then
    git worktree add -q "$dir" "$branch"
  else
    git worktree add -q -b "$branch" "$dir" "$base"
  fi
  echo "  [add ] $branch -> $dir"
}

step "1. 长生命周期分支常驻"
add_wt develop develop main

step "2. 并行任务 / 多 AI Agent 工位（各自独立提交，互不影响主工作区）"
add_wt feature-agents  feature/parallel-agents main
add_wt feature-billing feature/billing         main

cat > "$WT_ROOT/feature-agents/src/agent.py" <<'EOF'
"""并行任务调度骨架（工位 A 独立提交）。"""


def run(task: str) -> str:
    return f"agent running: {task}"
EOF
git -C "$WT_ROOT/feature-agents" add -A
git -C "$WT_ROOT/feature-agents" commit -q -m "feat(agents): 并行任务调度骨架"

cat > "$WT_ROOT/feature-billing/src/billing.py" <<'EOF'
"""计费模块骨架（工位 B 独立提交）。"""

TAX_RATE = 0.06


def total(amount: float) -> float:
    return round(amount * (1 + TAX_RATE), 2)
EOF
git -C "$WT_ROOT/feature-billing" add -A
git -C "$WT_ROOT/feature-billing" commit -q -m "feat(billing): 计费模块骨架"

step "3. 验证：所有工位共享同一对象库（无需 fetch / push）"
OBJ="$(git -C "$WT_ROOT/feature-agents" rev-parse HEAD)"
echo "  feature-agents HEAD      : $OBJ"
echo "  主工作区直接读取该对象   : $(git -C "$ROOT" cat-file -t "$OBJ")  (commit = 共享对象库)"
echo "  main  --git-common-dir   : $(git -C "$ROOT" rev-parse --path-format=absolute --git-common-dir)"
echo "  agent --git-common-dir   : $(git -C "$WT_ROOT/feature-agents" rev-parse --path-format=absolute --git-common-dir)"
echo "  主工作区 HEAD 仍停留在   : $(git -C "$ROOT" branch --show-current)"

step "4. 线上热修复：零上下文切换（主工作区不 checkout、不 stash）"
add_wt hotfix-1.0.1 hotfix/1.0.1 main
sed -i 's/VERSION = "1.0.0"/VERSION = "1.0.1"/' "$WT_ROOT/hotfix-1.0.1/src/app.py"
git -C "$WT_ROOT/hotfix-1.0.1" add -A
git -C "$WT_ROOT/hotfix-1.0.1" commit -q -m "hotfix: 版本号提升 1.0.1"
git -C "$WT_ROOT/hotfix-1.0.1" tag v1.0.1 2>/dev/null || true
echo "  修复内容: $(grep 'VERSION' "$WT_ROOT/hotfix-1.0.1/src/app.py" | head -1)"
git merge --ff-only hotfix/1.0.1
echo "  主工作区合入后版本: $(grep 'VERSION' "$ROOT/src/app.py" | head -1)"
echo "  主工作区仍是分支: $(git branch --show-current)"

step "5. PR 评审 / 一次性验证：detached 工位"
if [ ! -d "$WT_ROOT/review-pr-42" ]; then
  git worktree add -q --detach "$WT_ROOT/review-pr-42" main
fi
echo "  detached HEAD: $(git -C "$WT_ROOT/review-pr-42" rev-parse --short HEAD)"
echo "  该工位分支名: '$(git -C "$WT_ROOT/review-pr-42" branch --show-current)'  (空 = 分离 HEAD)"

step "6. 巡检 + 锁定常驻工位"
git worktree list
git worktree lock --reason "常驻集成分支，禁止 prune" "$WT_ROOT/develop" 2>/dev/null || true
git worktree list -v | sed 's/^/  /'

step "7. 规范回收：unlock -> remove -> prune"
git worktree unlock "$WT_ROOT/develop" 2>/dev/null || true
if [ -d "$WT_ROOT/review-pr-42" ]; then
  git worktree remove "$WT_ROOT/review-pr-42"
fi
git worktree prune
git worktree list | sed 's/^/  /'

step "完成"
echo "  分支清单:"
git branch --format='  %(refname:short)' | sed 's/^/  /'
echo "  tag 清单: $(git tag --list | tr '\n' ' ')"
