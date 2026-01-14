param(
  [string]$Path = (Get-Location).Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$makeAction = Join-Path (Join-Path (Split-Path -Parent $scriptDir) '02') 'make-action.ps1'

if (-not (Test-Path -LiteralPath $makeAction)) {
  throw "make-action.ps1 が見つかりません: $makeAction"
}

& $makeAction -Path $Path | Out-Host

