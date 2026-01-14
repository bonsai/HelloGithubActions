param(
  [switch]$InstallGh,

  [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Has-Command([string]$Name) {
  return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
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

function Ensure-Winget {
  if (-not (Has-Command winget)) {
    throw "winget が見つかりません。Microsoft Store の「App Installer」を入れてください。"
  }
}

if (Has-Command git) {
  Run git @('--version')
} else {
  Ensure-Winget
  Run winget @(
    'install',
    '--id', 'Git.Git',
    '--source', 'winget',
    '--accept-package-agreements',
    '--accept-source-agreements'
  )
}

if (-not (Has-Command git)) {
  Write-Host "Git のインストール後、PowerShellを開き直してから 'git --version' を確認してください。"
} else {
  Run git @('--version')
}

if ($InstallGh) {
  if (Has-Command gh) {
    Run gh @('--version')
  } else {
    Ensure-Winget
    Run winget @(
      'install',
      '--id', 'GitHub.cli',
      '--source', 'winget',
      '--accept-package-agreements',
      '--accept-source-agreements'
    )
  }
}

