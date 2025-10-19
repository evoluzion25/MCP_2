param(
  [string]$Version = 'latest',
  [string]$InstallDir = 'C:\DevWorkspace\MCP_2\bin'
)

$ErrorActionPreference = 'Stop'

function Write-Info($m){ Write-Host $m -ForegroundColor Cyan }
function Write-Ok($m){ Write-Host $m -ForegroundColor Green }
function Write-Warn($m){ Write-Host $m -ForegroundColor Yellow }
function Write-Err($m){ Write-Host $m -ForegroundColor Red }

function Ensure-Dir($p){ if (-not (Test-Path $p)) { New-Item -ItemType Directory -Path $p | Out-Null } }

$repo = 'bitwarden/sdk'
$apiBase = "https://api.github.com/repos/$repo/releases"
$assetExePatterns = @(
  '(?i)windows.*(amd64|x64).*\.exe$',
  '(?i)win.*(amd64|x64).*\.exe$',
  '(?i)windows.*\.exe$'
)
$assetZipPatterns = @(
  '(?i)windows.*(amd64|x64).*\.zip$',
  '(?i)win.*(amd64|x64).*\.zip$',
  '(?i)windows.*\.zip$'
)

Ensure-Dir $InstallDir
$dest = Join-Path $InstallDir 'bws.exe'
if (Test-Path $dest) { Remove-Item $dest -Force -ErrorAction SilentlyContinue }

function Find-Asset {
  param($assets)
  # Determine preferred architecture
  $osArch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture
  $preferArm = $false
  if ($osArch -eq [System.Runtime.InteropServices.Architecture]::Arm64) { $preferArm = $true }

  $primaryArch = $preferArm ? '(?i)(aarch64|arm64)' : '(?i)(x86_64|amd64)'
  $secondaryArch = $preferArm ? '(?i)(x86_64|amd64)' : '(?i)(aarch64|arm64)'

  $sequence = @(
    @{ arch=$primaryArch;  ext='exe' },
    @{ arch=$primaryArch;  ext='zip' },
    @{ arch=$secondaryArch; ext='exe' },
    @{ arch=$secondaryArch; ext='zip' }
  )

  foreach ($rule in $sequence) {
    $arch = $rule.arch
    $ext = $rule.ext
    $cands = $assets | Where-Object { $_.name -match '(?i)(pc-windows|windows|win)'
                                      -and $_.name -match $arch
                                      -and $_.name -match ( $ext -eq 'exe' ? '(?i)\.exe$' : '(?i)\.zip$' ) }
    $cand = $cands | Select-Object -First 1
    if ($cand) { return $cand }
  }

  # Fallback to any Windows asset
  foreach ($p in $assetExePatterns) {
    $cand = $assets | Where-Object { $_.name -match $p } | Select-Object -First 1
    if ($cand) { return $cand }
  }
  foreach ($p in $assetZipPatterns) {
    $cand = $assets | Where-Object { $_.name -match $p } | Select-Object -First 1
    if ($cand) { return $cand }
  }
  return $null
}

function Get-ReleaseJson {
  param([string]$ver)
  $headers = @{ 'User-Agent' = 'PowerShell'; 'Accept'='application/vnd.github+json' }
  if ($ver -eq 'latest') {
    # Search recent releases for one that contains a Windows bws asset
    $rels = Invoke-RestMethod -Headers $headers -Uri ("https://api.github.com/repos/" + $repo + "/releases?per_page=50")
    foreach ($r in $rels) {
      $a = Find-Asset -assets $r.assets
      if ($a) { return $r }
    }
    throw 'No suitable release found with a Windows bws asset.'
  }
  else {
    return Invoke-RestMethod -Headers $headers -Uri "$apiBase/tags/$ver"
  }
}

function Download-File {
  param([string]$url,[string]$path)
  $headers = @{ 'User-Agent'='PowerShell'; 'Accept'='application/octet-stream' }
  Invoke-WebRequest -Headers $headers -Uri $url -OutFile $path -UseBasicParsing
}

Write-Info "Resolving Bitwarden SM CLI (bws) release: $Version"
$rel = Get-ReleaseJson -ver $Version
if (-not $rel) { throw 'Failed to fetch release metadata' }

function Find-Asset {
  param($assets)
  foreach ($p in $assetExePatterns) {
    $cand = $assets | Where-Object { $_.name -match $p } | Select-Object -First 1
    if ($cand) { return $cand }
  }
  foreach ($p in $assetZipPatterns) {
    $cand = $assets | Where-Object { $_.name -match $p } | Select-Object -First 1
    if ($cand) { return $cand }
  }
  return $null
}

$asset = Find-Asset -assets $rel.assets
if (-not $asset) { throw 'Could not find a Windows (x64) asset (.exe or .zip) in release.' }

function Try-Install-From-Asset {
  param($asset)
  Write-Info "Trying asset: $($asset.name)"
  $tmp = Join-Path $env:TEMP $asset.name
  if (Test-Path $tmp) { Remove-Item $tmp -Force -ErrorAction SilentlyContinue }
  if ($asset.name -match '(?i)\.exe$') {
    Download-File -url $asset.browser_download_url -path $tmp
    if (-not (Test-Path $tmp)) { return $false }
    $size = (Get-Item $tmp).Length
    if ($size -lt 1024*100 -and $asset.url) {
      $headers = @{ 'User-Agent'='PowerShell'; 'Accept'='application/octet-stream' }
      Invoke-WebRequest -Headers $headers -Uri $asset.url -OutFile $tmp -UseBasicParsing
    }
    Copy-Item -Path $tmp -Destination $dest -Force
    try { Unblock-File -Path $dest -ErrorAction SilentlyContinue } catch {}
  } else {
    Download-File -url $asset.browser_download_url -path $tmp
    if (-not (Test-Path $tmp)) { return $false }
    $tmpDir = Join-Path $env:TEMP ([System.IO.Path]::GetFileNameWithoutExtension($asset.name))
    if (Test-Path $tmpDir) { Remove-Item $tmpDir -Recurse -Force }
    Expand-Archive -LiteralPath $tmp -DestinationPath $tmpDir -Force
    $exe = Get-ChildItem -Path $tmpDir -Recurse -Filter 'bws.exe' | Select-Object -First 1
    if (-not $exe) { return $false }
    Copy-Item -Path $exe.FullName -Destination $dest -Force
    try { Unblock-File -Path $dest -ErrorAction SilentlyContinue } catch {}
  }
  try {
    $ver = & $dest --version 2>$null
    if ($LASTEXITCODE -eq 0 -and $ver) { Write-Ok "bws installed: $ver"; return $true }
  } catch { }
  return $false
}

# Build ordered candidate list (prefer x86_64/amd64, then arm64)
$assets = $rel.assets
$ordered = @()
$ordered += $assets | Where-Object { $_.name -match '(?i)(pc-windows|windows|win)' -and $_.name -match '(?i)(x86_64|amd64)' -and $_.name -match '(?i)\.exe$' }
$ordered += $assets | Where-Object { $_.name -match '(?i)(pc-windows|windows|win)' -and $_.name -match '(?i)(x86_64|amd64)' -and $_.name -match '(?i)\.zip$' }
$ordered += $assets | Where-Object { $_.name -match '(?i)(pc-windows|windows|win)' -and $_.name -match '(?i)(aarch64|arm64)' -and $_.name -match '(?i)\.exe$' }
$ordered += $assets | Where-Object { $_.name -match '(?i)(pc-windows|windows|win)' -and $_.name -match '(?i)(aarch64|arm64)' -and $_.name -match '(?i)\.zip$' }
$ordered += $assets | Where-Object { $_.name -match '(?i)(pc-windows|windows|win)' -and $_.name -match '(?i)\.exe$' }
$ordered += $assets | Where-Object { $_.name -match '(?i)(pc-windows|windows|win)' -and $_.name -match '(?i)\.zip$' }

$installed = $false
foreach ($a in $ordered) {
  if (Try-Install-From-Asset -asset $a) { $installed = $true; break }
}

if (-not $installed) { throw 'Failed to install a working bws binary from available assets.' }

# Suggest PATH update
$binDir = [Environment]::GetEnvironmentVariable('PATH','User')
if ($binDir -notmatch [Regex]::Escape($InstallDir)) {
  [Environment]::SetEnvironmentVariable('PATH', ($binDir + ';' + $InstallDir).Trim(';'), 'User')
  Write-Warn "Added $InstallDir to User PATH. Open a new shell for PATH changes to take effect."
}
