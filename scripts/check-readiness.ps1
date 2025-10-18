$ErrorActionPreference='Stop'

function Get-ManifestKeys {
  $jsonPath = Join-Path $PSScriptRoot '..' 'secrets' 'manifest.json'
  if (-not (Test-Path $jsonPath)) { throw "Missing manifest: $jsonPath" }
  $mf = (Get-Content $jsonPath -Raw) | ConvertFrom-Json
  return $mf.keys.PSObject.Properties | ForEach-Object { $_.Name, $mf.keys.($_.Name).mcp }
}

Write-Host "== Docker MCP readiness ==" -ForegroundColor Cyan

# 1) Filesystem allowlist
$config = docker mcp config read 2>$null
Write-Host "Config: $config" -ForegroundColor DarkGray

# 2) Secrets present
$secretList = docker mcp secret ls 2>$null
$present = @{}
$secretList | ForEach-Object {
  $line = $_.Trim(); if (-not $line) { return }
  $name = ($line -split '\|')[0].Trim()
  if ($name) { $present[$name] = $true }
}

$manifestPairs = @()
$mfPath = Join-Path $PSScriptRoot '..' 'secrets' 'manifest.json'
$mf = (Get-Content $mfPath -Raw) | ConvertFrom-Json
$keys = $mf.keys.PSObject.Properties | ForEach-Object { $_.Name }
foreach ($k in $keys){
  $m = $mf.keys.$k
  $mcp = $m.mcp
  $status = if ($present.ContainsKey($mcp)) { 'OK' } else { 'MISSING' }
  $manifestPairs += [pscustomobject]@{ ENV=$k; MCP=$mcp; Status=$status }
}

Write-Host "Secrets status:" -ForegroundColor Cyan
$manifestPairs | Sort-Object Status, ENV | Format-Table -AutoSize

# 3) Catalogs/servers
Write-Host "Servers enabled:" -ForegroundColor Cyan
(docker mcp server ls 2>$null)

Write-Host "Catalog mcp2-services:" -ForegroundColor Cyan
(docker mcp catalog show mcp2-services 2>$null)

Write-Host "== Done ==" -ForegroundColor Cyan
