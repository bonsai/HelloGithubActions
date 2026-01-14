param(
  [string]$Path = (Get-Location).Path,

  [string]$Message = 'update',

  [string]$Branch = 'main',

  [string]$Remote = 'origin',

  [switch]$OpenWeb,

  [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Require-Command([string]$Name) {
  if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
    throw "$Name が見つかりません。PATHを確認してください。"
  }
}

function Run([string]$File, [string[]]$CommandArgs) {
  $line = ($CommandArgs | ForEach-Object {
    if ($_ -match '\s') { '"' + ($_ -replace '"','\"') + '"' } else { $_ }
  }) -join ' '
  Write-Host ($File + ' ' + $line)
  if (-not $DryRun) {
    & $File @CommandArgs | Out-Host
    if ($LASTEXITCODE -ne 0) { throw "$File failed: $LASTEXITCODE" }
  }
}

function Has-Upstream([string]$RepoPath) {
  & git -C $RepoPath rev-parse --abbrev-ref --symbolic-full-name '@{u}' *> $null
  return ($LASTEXITCODE -eq 0)
}

Require-Command git

$resolvedPath = (Resolve-Path -LiteralPath $Path).Path
Set-Location $resolvedPath

if (-not (Test-Path -LiteralPath (Join-Path $resolvedPath '.git'))) {
  throw ".git が見つかりません: $resolvedPath"
}

Run git @('-C', $resolvedPath, 'fetch', '--prune', $Remote)

& git -C $resolvedPath show-ref --verify --quiet ("refs/heads/$Branch")
if ($LASTEXITCODE -ne 0) {
  Run git @('-C', $resolvedPath, 'checkout', '-b', $Branch)
} else {
  $current = (& git -C $resolvedPath rev-parse --abbrev-ref HEAD).Trim()
  if ($current -ne $Branch) {
    Run git @('-C', $resolvedPath, 'checkout', $Branch)
  }
}

Run git @('-C', $resolvedPath, 'add', '-A')

& git -C $resolvedPath diff --cached --quiet
$hasStaged = ($LASTEXITCODE -ne 0)
if (-not $hasStaged) {
  Write-Host "no changes"
  if ($OpenWeb) {
    Require-Command gh
    Run gh @('repo', 'view', '--web')
  }
  exit 0
}

Run git @('-C', $resolvedPath, 'commit', '-m', $Message)

if (Has-Upstream $resolvedPath) {
  Run git @('-C', $resolvedPath, 'push')
} else {
  Run git @('-C', $resolvedPath, 'push', '-u', $Remote, $Branch)
}

if ($OpenWeb) {
  Require-Command gh
  Run gh @('repo', 'view', '--web')
}

