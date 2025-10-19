param(
  [string]$EnvFile = 'C:\Users\ryan\Apps\GitHub\dev-env-config\credentials.env.template',
  [string]$ProjectName = 'MCP_2',
  [string]$ProjectId,
  [switch]$Bootstrap,
  [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

function Write-Info($m){ Write-Host $m -ForegroundColor Cyan }
function Write-Ok($m){ Write-Host $m -ForegroundColor Green }
function Write-Warn($m){ Write-Host $m -ForegroundColor Yellow }

function Get-BwsPath {
  $cmd = Get-Command bws -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Path }
  $fallback = 'C:\DevWorkspace\MCP_2\bin\bws.exe'
  if (Test-Path $fallback) { return $fallback }
  throw 'bws CLI not found. Install it and/or ensure it is on PATH.'
}

function Get-Manifest() {
  $jsonPath = Join-Path $PSScriptRoot '..' 'secrets' 'manifest.json'
  if (-not (Test-Path $jsonPath)) { throw "Missing manifest: $jsonPath" }
  return (Get-Content $jsonPath -Raw) | ConvertFrom-Json
}

if (-not (Test-Path $EnvFile)) { throw "Env file not found: $EnvFile" }
if (-not $env:BWS_ACCESS_TOKEN) { throw 'BWS_ACCESS_TOKEN is not set in this shell.' }

$bws = Get-BwsPath
Write-Info "Using bws: $bws"

Write-Info 'Resolving project...'
if ($ProjectId) {
  $projectId = $ProjectId
  Write-Ok "Project (provided): $projectId"
}
else {
  $pidPath = Join-Path $PSScriptRoot '..' 'secrets' 'project-id.txt'
  if (-not $ProjectId -and (Test-Path $pidPath)) {
    $projIdFromFile = (Get-Content $pidPath -Raw).Trim()
    if ($projIdFromFile) { $projectId = $projIdFromFile; Write-Ok "Project (from file): $projectId" }
  }
  if ($projectId) { }
  else {
  $projListJson = & $bws project list --output json
  $projList = @()
  if ($LASTEXITCODE -eq 0 -and $projListJson) { $projList = $projListJson | ConvertFrom-Json } else { $projList = @() }
  $project = $projList | Where-Object { $_.name -eq $ProjectName } | Select-Object -First 1
  if (-not $project) {
    if ($DryRun) { Write-Warn "[DRY-RUN] Would create project '$ProjectName'" }
    else {
      $createdJson = & $bws project create $ProjectName --output json
      if ($LASTEXITCODE -ne 0) { throw 'Failed to create project.' }
      $project = $createdJson | ConvertFrom-Json
    }
  }
  $projectId = $project.id
  if (-not $projectId) { throw 'Project id not resolved.' }
  Write-Ok "Project: $ProjectName ($projectId)"
  }
}

# Build key set from manifest
$mf = Get-Manifest
$manifestKeys = $mf.keys.PSObject.Properties | ForEach-Object { $_.Name }

# Parse env file
$pairs = @{}
Get-Content $EnvFile | ForEach-Object {
  $line = $_.Trim(); if (-not $line -or $line.StartsWith('#')) { return }
  $sp = $line -split '=', 2; if ($sp.Count -ne 2) { return }
  $key = $sp[0].Trim(); $val = $sp[1].Trim()
  if ($val.StartsWith('"') -and $val.EndsWith('"')) { $val = $val.Trim('"') }
  if ($manifestKeys -contains $key) {
    # skip empty or placeholder values like <...>
    if ($val -and ($val -notmatch '^<.+>$')) { $pairs[$key] = $val }
  }
}

Write-Info ("Found {0} keys with real values to import" -f $pairs.Count)

if ($pairs.Count -eq 0 -and -not $Bootstrap) {
  Write-Warn 'No keys to import and Bootstrap not requested. Exiting.'
  return
}

# Index existing secrets in project
$existing = @{}
$seclistJson = $null
try {
  $seclistJson = & $bws secret list $projectId --output json
} catch {}
if ($LASTEXITCODE -eq 0 -and $seclistJson) {
  $seclist = $seclistJson | ConvertFrom-Json
  foreach ($s in $seclist) { $existing[$s.key] = $s }
} else {
  Write-Warn 'Could not list existing secrets (possibly insufficient permissions). Proceeding with create path only.'
}

$created = 0; $updated = 0
foreach ($k in $pairs.Keys) {
  $v = $pairs[$k]
  if ($DryRun) { Write-Warn "[DRY-RUN] $k"; continue }
  if ($existing.ContainsKey($k)) {
    $sid = $existing[$k].id
    # Update value silently
    $null = & $bws secret edit $sid --value "$v" --output none
    if ($LASTEXITCODE -eq 0) { $updated++ } else { Write-Warn "Failed updating $k (id=$sid)" }
  } else {
    # Create new secret
    $null = & $bws secret create $k "$v" $projectId --output none
    if ($LASTEXITCODE -eq 0) { $created++ } else { Write-Warn "Failed creating $k" }
  }
}

Write-Ok ("Secrets created: {0}, updated: {1}" -f $created, $updated)

if ($Bootstrap) {
  Write-Info 'Bootstrapping Docker MCP secrets from bws project...'
  # Reload secrets and map by key
  $seclistJson2 = & $bws secret list $projectId --output json
  $kv = @{}
  if ($LASTEXITCODE -eq 0 -and $seclistJson2) {
    $seclist2 = $seclistJson2 | ConvertFrom-Json
    foreach ($s in $seclist2) { $kv[$s.key] = $s.value }
  }
  # Apply per manifest
  $applied = 0
  $keys = $mf.keys.PSObject.Properties | ForEach-Object { $_.Name }
  foreach ($k in $keys) {
    $m = $mf.keys.$k
    $mcp = $m.mcp
    if ($kv.ContainsKey($k) -and $kv[$k]) {
      $val = $kv[$k]
      if ($DryRun) { Write-Warn "[DRY-RUN] docker mcp secret set $mcp" }
      else {
        docker mcp secret set "$mcp=$val" | Out-Null
        $applied++
      }
    }
  }
  Write-Ok ("Applied {0} secrets to Docker MCP." -f $applied)
}

Write-Ok 'Done.'
