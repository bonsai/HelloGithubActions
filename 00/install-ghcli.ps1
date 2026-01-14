param(
  [ValidateSet('https', 'ssh')]
  [string]$GitProtocol = 'https',

  [switch]$SetupGit,

  [switch]$Login,

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
  }
}

Require-Command gh

Run gh @('--version')

if ($Login) {
  Run gh @('auth', 'login')
}

if (-not $DryRun) {
  & gh auth status *> $null
  if ($LASTEXITCODE -ne 0) {
    throw "GitHub CLI の認証が必要です。'gh auth login' を実行してください。"
  }
}

Run gh @('config', 'set', 'git_protocol', $GitProtocol)

if ($SetupGit) {
  Run gh @('auth', 'setup-git')
}

Run gh @('auth', 'status')
Run gh @('config', 'get', 'git_protocol')

