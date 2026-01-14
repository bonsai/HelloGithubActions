param(
  [Parameter(Mandatory = $true, Position = 0)]
  [string]$RepoUrl,

  [string]$DestPath = (Get-Location).Path,

  [string]$DirName,

  [ValidateSet('backup', 'delete', 'fail')]
  [string]$Existing = 'backup',

  [string]$BackupRoot,

  [switch]$Renew,

  [switch]$OpenWeb,

  [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$renewClone = Join-Path $scriptDir 'renew.clone.ps1'

if (-not (Test-Path -LiteralPath $renewClone)) {
  throw "renew.clone.ps1 が見つかりません: $renewClone"
}

$mode = if ($Renew) { 'renew' } else { 'pull' }

& $renewClone `
  -RepoUrl $RepoUrl `
  -DestPath $DestPath `
  -DirName $DirName `
  -Mode $mode `
  -Existing $Existing `
  -BackupRoot $BackupRoot `
  -OpenWeb:$OpenWeb `
  -DryRun:$DryRun

