param(
  [Parameter(Position = 0)]
  [string]$RepoName,

  [string]$Owner,

  [ValidateSet('public', 'private')]
  [string]$Visibility = 'private',

  [string]$Path = (Get-Location).Path,

  [string]$Description = '',

  [switch]$HelloActions,

  [switch]$NoPush,

  [switch]$OpenWeb
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Require-Command([string]$Name) {
  if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
    throw "$Name が見つかりません。PATHを確認してください。"
  }
}

function Has-GitCommit {
  & git rev-parse --verify HEAD *> $null
  return ($LASTEXITCODE -eq 0)
}

function Ensure-File([string]$FilePath, [string]$Content) {
  if (-not (Test-Path -LiteralPath $FilePath)) {
    $dir = Split-Path -Parent $FilePath
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
      New-Item -ItemType Directory -Path $dir -Force *> $null
    }
    Set-Content -LiteralPath $FilePath -Value $Content -Encoding UTF8
  }
}

Require-Command git
Require-Command gh

$resolvedPath = (Resolve-Path -LiteralPath $Path).Path
Set-Location $resolvedPath

if (-not $RepoName -or $RepoName.Trim().Length -eq 0) {
  $RepoName = Split-Path -Leaf $resolvedPath
}

Write-Host "path: $resolvedPath"
Write-Host "repo: $RepoName"
Write-Host "visibility: $Visibility"

try {
  & gh auth status *> $null
  if ($LASTEXITCODE -ne 0) { throw "auth failed" }
} catch {
  throw "GitHub CLI の認証が必要です。先に 'gh auth login' を実行してください。"
}

if (-not (Test-Path -LiteralPath (Join-Path $resolvedPath '.git'))) {
  & git init | Out-Host
}

& git branch -M main *> $null

$originUrl = $null
try {
  $originUrl = (& git remote get-url origin 2>$null)
} catch {
  $originUrl = $null
}
if ($originUrl) {
  throw "このフォルダには既に origin が設定されています: $originUrl"
}

if (-not (Has-GitCommit)) {
  Ensure-File (Join-Path $resolvedPath 'README.md') "# $RepoName`n"
}

if ($HelloActions) {
  $createActions = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'create-actions.ps1'
  & $createActions -Path $resolvedPath | Out-Host
}

& git add -A | Out-Host

& git diff --cached --quiet
$hasStaged = ($LASTEXITCODE -ne 0)

if (-not (Has-GitCommit) -or $hasStaged) {
  & git commit -m "init" | Out-Host
}

$visibilityFlag = if ($Visibility -eq 'public') { '--public' } else { '--private' }
$pushFlag = if ($NoPush) { '' } else { '--push' }
$target = if ($Owner -and $Owner.Trim().Length -gt 0) { "$Owner/$RepoName" } else { $RepoName }
$descFlag = if ($Description -and $Description.Trim().Length -gt 0) { @('--description', $Description) } else { @() }

$args = @('repo', 'create', $target, $visibilityFlag, '--source=.', '--remote=origin') + $descFlag
if ($pushFlag) { $args += $pushFlag }

Write-Host ("gh " + ($args -join ' '))
& gh @args | Out-Host

if ($OpenWeb) {
  & gh repo view --web | Out-Host
}

