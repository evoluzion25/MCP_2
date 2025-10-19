param(
  [string]$EnvFile = 'C:\Users\ryan\Apps\GitHub\dev-env-config\credentials.env.template',
  [string]$ProjectId,
  [string]$ProjectName = 'MCP_2',
  [switch]$Bootstrap,
  [switch]$DryRun
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

function Read-EnvFile($path){
  $map=@{}
  if (-not (Test-Path $path)) { return $map }
  Get-Content $path | ForEach-Object {
    $line=$_.Trim(); if (-not $line -or $line.StartsWith('#')) { return }
    $sp=$line -split '=',2; if ($sp.Count -ne 2) { return }
    $k=$sp[0].Trim(); $v=$sp[1].Trim(); if ($v.StartsWith('"') -and $v.EndsWith('"')) { $v=$v.Trim('"') }
    if ($v -and ($v -notmatch '^<.+>$')) { $map[$k]=$v }
  }
  return $map
}

if (-not $env:BWS_ACCESS_TOKEN) { throw 'BWS_ACCESS_TOKEN is not set in this shell.' }

Write-Info 'Syncing env -> Bitwarden SM...'
$projId = Get-ProjectId -name $ProjectName -explicit $ProjectId
Write-Ok "Project: $ProjectName ($projId)"
$mf = Get-Manifest
$keys = $mf.keys.PSObject.Properties | ForEach-Object { $_.Name }
$envMap = Read-EnvFile -path $EnvFile

# Fetch current secrets
$existing=@{}
$seclistJson = & bws secret list $projId --output json
if ($LASTEXITCODE -eq 0 -and $seclistJson){
  $seclist = $seclistJson | ConvertFrom-Json
  foreach ($s in $seclist) { $existing[$s.key]=$s }
}

$created=0; $updated=0; $skipped=0
foreach ($k in $keys){
  if (-not $envMap.ContainsKey($k)) { $skipped++; continue }
  $val = $envMap[$k]
  if ($DryRun){ Write-Warn "[DRY-RUN] Would upsert $k"; continue }
  if ($existing.ContainsKey($k)){
    $sid = $existing[$k].id
    $null = & bws secret edit $sid --value "$val" --output none
    if ($LASTEXITCODE -eq 0) { $updated++ } else { Write-Warn "Failed to update $k" }
  } else {
    $null = & bws secret create $k "$val" $projId --output none
    if ($LASTEXITCODE -eq 0) { $created++ } else { Write-Warn "Failed to create $k" }
  }
}

Write-Ok ("Created: {0}, Updated: {1}, Skipped(no env value): {2}" -f $created,$updated,$skipped)

if ($Bootstrap){
  Write-Info 'Bootstrapping Docker MCP secrets...'
  pwsh -NoProfile -File (Join-Path $PSScriptRoot 'sm-import-from-env.ps1') -ProjectId $projId -Bootstrap | Out-Null
  Write-Ok 'Bootstrap complete.'
}
