param(
  [Parameter(Mandatory = $true, Position = 0)]
  [string]$RepoUrl,

  [string]$DestPath = (Get-Location).Path,

  [string]$DirName,

  [ValidateSet('pull', 'renew')]
  [string]$Mode = 'renew',

  [ValidateSet('backup', 'delete', 'fail')]
  [string]$Existing = 'backup',

  [string]$BackupRoot,

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

function Get-RepoDirName([string]$Url) {
  $u = $Url.TrimEnd('/')
  $leaf = ($u -split '/')[ -1 ]
  if ($leaf.ToLower().EndsWith('.git')) {
    return $leaf.Substring(0, $leaf.Length - 4)
  }
  return $leaf
}

function Get-RepoSlug([string]$Url) {
  $u = $Url.Trim()
  if ($u -match '^https?://github\.com/([^/]+)/([^/]+?)(?:\.git)?/?$') {
    return ($Matches[1] + '/' + $Matches[2])
  }
  if ($u -match '^git@github\.com:([^/]+)/([^/]+?)(?:\.git)?$') {
    return ($Matches[1] + '/' + $Matches[2])
  }
  return $null
}

function Is-GitRepo([string]$Path) {
  return (Test-Path -LiteralPath (Join-Path $Path '.git'))
}

function Get-OriginDefaultBranch([string]$RepoPath) {
  & git -C $RepoPath symbolic-ref refs/remotes/origin/HEAD 2>$null *> $null
  if ($LASTEXITCODE -eq 0) {
    $ref = (& git -C $RepoPath symbolic-ref refs/remotes/origin/HEAD).Trim()
    if ($ref -match '^refs/remotes/origin/(.+)$') { return $Matches[1] }
  }
  return 'main'
}

Require-Command git

$resolvedDest = (Resolve-Path -LiteralPath $DestPath).Path
if (-not $DirName -or $DirName.Trim().Length -eq 0) {
  $DirName = Get-RepoDirName $RepoUrl
}

$repoSlug = Get-RepoSlug $RepoUrl

$targetPath = Join-Path $resolvedDest $DirName

Write-Host "repo: $RepoUrl"
Write-Host "dest: $targetPath"
Write-Host "mode: $Mode"
Write-Host "existing: $Existing"

if (Test-Path -LiteralPath $targetPath) {
  if (Is-GitRepo $targetPath) {
    if ($Mode -eq 'pull') {
      Run git @('-C', $targetPath, 'pull', '--ff-only')
      if ($OpenWeb) {
        Require-Command gh
        if ($repoSlug) { Run gh @('repo', 'view', '--web', '--repo', $repoSlug) } else { Run gh @('repo', 'view', '--web') }
      }
      return
    }

    Run git @('-C', $targetPath, 'fetch', '--prune', 'origin')
    $branch = Get-OriginDefaultBranch $targetPath
    Run git @('-C', $targetPath, 'reset', '--hard', "origin/$branch")
    Run git @('-C', $targetPath, 'clean', '-fdx')
    if ($OpenWeb) {
      Require-Command gh
      if ($repoSlug) { Run gh @('repo', 'view', '--web', '--repo', $repoSlug) } else { Run gh @('repo', 'view', '--web') }
    }
    return
  }

  if ($Existing -eq 'fail') {
    throw "既に存在しますがgitリポジトリではありません: $targetPath"
  }

  if ($Existing -eq 'delete') {
    Write-Host "remove: $targetPath"
    if (-not $DryRun) {
      Remove-Item -LiteralPath $targetPath -Recurse -Force
    }
  }

  if ($Existing -eq 'backup') {
    if (-not $BackupRoot -or $BackupRoot.Trim().Length -eq 0) {
      $BackupRoot = Join-Path $resolvedDest '_backup'
    }
    if (-not $DryRun) {
      New-Item -ItemType Directory -Path $BackupRoot -Force *> $null
    }
    $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $backupPath = Join-Path $BackupRoot ($DirName + '_' + $stamp)
    Write-Host "move: $targetPath -> $backupPath"
    if (-not $DryRun) {
      Move-Item -LiteralPath $targetPath -Destination $backupPath
    }
  }
}

Run git @('clone', $RepoUrl, $targetPath)
if ($OpenWeb) {
  Require-Command gh
  if ($repoSlug) { Run gh @('repo', 'view', '--web', '--repo', $repoSlug) } else { Run gh @('repo', 'view', '--web') }
}
