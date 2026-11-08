#!/usr/bin/env bash
# 搭建工业级 "bare 中枢 + 常驻 worktree" 拓扑
# 用法: bash scripts/setup-bare-worktrees.sh <git-url> [目标目录]
#
# 产物:
#   <目标目录>/.bare/          共享对象库 + 全部引用（core.bare=true，中枢本身不是工作区）
#   <目标目录>/.git            gitdir 指针文件
#   <目标目录>/<默认分支>/      常驻发布基线工位
#   <目标目录>/develop/         常驻集成分支工位
#
# 为什么用 `git init --bare` 而不是 `git clone --bare`，见 docs/git-worktree-industrial-guide.md §4.3
set -euo pipefail

URL="${1:?用法: $0 <git-url> [目标目录]}"
DEST="${2:-./worktree-hub}"

mkdir -p "$DEST"
cd "$DEST"

git init -q --bare .bare
printf 'gitdir: ./.bare\n' > .git

git remote add origin "$URL"
git fetch -q origin
git remote set-head origin -a >/dev/null 2>&1 || true

BASE="$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##' || true)"
[ -n "$BASE" ] || BASE=main

git worktree add -q --track -b "$BASE" "$BASE" "origin/$BASE"
git worktree add -q -b develop develop "$BASE"

echo "中枢已就绪: $(pwd)"
echo "注意: 中枢根目录不是工作区，工作区操作请用 git -C <工位> ..."
echo
git worktree list
