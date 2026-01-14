param(
  [string]$Path = (Get-Location).Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$resolvedPath = (Resolve-Path -LiteralPath $Path).Path
Set-Location $resolvedPath

function Ensure-File([string]$FilePath, [string]$Content) {
  if (-not (Test-Path -LiteralPath $FilePath)) {
    $dir = Split-Path -Parent $FilePath
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
      New-Item -ItemType Directory -Path $dir -Force *> $null
    }
    Set-Content -LiteralPath $FilePath -Value $Content -Encoding UTF8
  }
}

$hello = @"
name: hello-actions

on:
  workflow_dispatch: {}
  pull_request:
    branches: [ "main" ]

jobs:
  hello:
    runs-on: ubuntu-latest
    steps:
      - name: Say hello
        run: |
          echo "Hello from GitHub Actions"
          echo "repo: `${{ github.repository }}"
          echo "actor: `${{ github.actor }}"
          echo "event: `${{ github.event_name }}"
"@

Ensure-File (Join-Path $resolvedPath '.github/workflows/hello.yml') $hello

