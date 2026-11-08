# 搭建工业级 "bare 中枢 + 常驻 worktree" 拓扑（PowerShell 版）
# 用法: .\scripts\setup-bare-worktrees.ps1 -Url <git-url> [-Dest <目标目录>]
# 说明见 docs/git-worktree-industrial-guide.md §4.2 / §4.3
param(
    [Parameter(Mandatory = $true)][string]$Url,
    [string]$Dest = "./worktree-hub"
)

$ErrorActionPreference = "Stop"

function Invoke-Git {
    param([string[]]$GitArgs)
    & git @GitArgs
    if ($LASTEXITCODE -ne 0) { throw "git $($GitArgs -join ' ') 执行失败 (exit $LASTEXITCODE)" }
}

New-Item -ItemType Directory -Force -Path $Dest | Out-Null
Push-Location $Dest
try {
    Invoke-Git @("init", "-q", "--bare", ".bare")

    # .git 必须是纯文本指针文件（无 BOM）
    Set-Content -Path .git -Value 'gitdir: ./.bare' -Encoding ascii

    Invoke-Git @("remote", "add", "origin", $Url)
    Invoke-Git @("fetch", "-q", "origin")
    & git remote set-head origin -a 2>$null | Out-Null

    $headRef = & git symbolic-ref --short refs/remotes/origin/HEAD 2>$null
    if (-not $headRef) { $headRef = "origin/main" }
    $base = $headRef -replace '^origin/', ''

    Invoke-Git @("worktree", "add", "-q", "--track", "-b", $base, $base, "origin/$base")
    Invoke-Git @("worktree", "add", "-q", "-b", "develop", "develop", $base)

    Write-Host "中枢已就绪: $(Get-Location)"
    Write-Host "注意: 中枢根目录不是工作区，工作区操作请用 git -C <工位> ..."
    Write-Host ""
    Invoke-Git @("worktree", "list")
}
finally {
    Pop-Location
}
