param(
  [string]$ProjectId,
  [string]$ProjectName = 'MCP_2',
  [string]$EnvFile,
  [switch]$Bootstrap
)

$ErrorActionPreference='Stop'

function Write-Info($m){ Write-Host $m -ForegroundColor Cyan }
function Write-Ok($m){ Write-Host $m -ForegroundColor Green }
function Write-Warn($m){ Write-Host $m -ForegroundColor Yellow }

function Get-Manifest() {
  $jsonPath = Join-Path $PSScriptRoot '..' 'secrets' 'manifest.json'
  if (-not (Test-Path $jsonPath)) { throw "Missing manifest: $jsonPath" }
  return (Get-Content $jsonPath -Raw) | ConvertFrom-Json
}

function Get-ProjectId($name,$explicit) {
  if ($explicit) { return $explicit }
  $idFile = Join-Path $PSScriptRoot '..' 'secrets' 'project-id.txt'
  if (Test-Path $idFile) { return (Get-Content $idFile -Raw).Trim() }
  $js = & bws project list --output json
  if ($LASTEXITCODE -ne 0) { throw 'Failed to list projects. Is BWS_ACCESS_TOKEN set?' }
  $projects = $js | ConvertFrom-Json
  $p = $projects | Where-Object { $_.name -eq $name } | Select-Object -First 1
  if (-not $p) { throw "Project not found: $name" }
  return $p.id
}

function Get-EnvMap($path) {
  $map=@{}
  if ($path -and (Test-Path $path)) {
    Get-Content $path | ForEach-Object {
      $line=$_.Trim(); if (-not $line -or $line.StartsWith('#')) { return }
      $sp=$line -split '=',2; if ($sp.Count -ne 2) { return }
      $k=$sp[0].Trim(); $v=$sp[1].Trim(); if ($v.StartsWith('"') -and $v.EndsWith('"')) { $v=$v.Trim('"') }
      if ($v -and ($v -notmatch '^<.+>$')) { $map[$k]=$v }
    }
  }
  return $map
}

Write-Info 'Filling missing Bitwarden SM secrets for project...'
$projId = Get-ProjectId -name $ProjectName -explicit $ProjectId
Write-Ok "Project: $ProjectName ($projId)"

$mf = Get-Manifest
$need = $mf.keys.PSObject.Properties | ForEach-Object { $_.Name }
$haveMap=@{}
$listJson = & bws secret list $projId --output json
if ($LASTEXITCODE -eq 0 -and $listJson) {
  $list = $listJson | ConvertFrom-Json
  foreach ($s in $list) { $haveMap[$s.key] = $true }
}

$envMap = Get-EnvMap -path $EnvFile
$created=0; $skipped=0
foreach ($k in $need) {
  if ($haveMap.ContainsKey($k)) { continue }
  $val=$null
  if ($envMap.ContainsKey($k)) { $val=$envMap[$k] }
  if (-not $val) {
    Write-Info "Enter value for $k (input hidden):"
    $sec = Read-Host -AsSecureString -Prompt $k
    if (-not $sec) { Write-Warn "Skipped $k (no input)"; $skipped++; continue }
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
    try { $val = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr) } finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
  }
  if ($val) {
    $null = & bws secret create $k "$val" $projId --output none
    if ($LASTEXITCODE -eq 0) { $created++ } else { Write-Warn "Failed creating $k" }
  }
}

Write-Ok ("Created {0} new secrets; skipped {1}." -f $created, $skipped)

if ($Bootstrap) {
  Write-Info 'Bootstrapping Docker MCP secrets...'
  pwsh -NoProfile -File (Join-Path $PSScriptRoot 'sm-import-from-env.ps1') -ProjectId $projId -Bootstrap | Out-Null
  Write-Ok 'Bootstrap complete.'
}
