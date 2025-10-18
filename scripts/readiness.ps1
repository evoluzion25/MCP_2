$ErrorActionPreference='Stop'

Write-Host "MCP readiness check" -ForegroundColor Cyan

# Check enabled servers
$servers = docker mcp server ls 2>$null
Write-Host "Enabled servers: $servers" -ForegroundColor DarkGray

# Required secrets per server (minimal set)
$required = @{
  'brave'      = @('brave.api_key')
  'exa'        = @('exa.api_key')
  'clickup'    = @('clickup.api_key','clickup.team_id')
}

$secrets = docker mcp secret ls 2>$null | ForEach-Object {
  ($_ -split '\|')[0].Trim()
} | Where-Object { $_ }

foreach ($srv in $required.Keys) {
  $missing = @()
  foreach ($name in $required[$srv]) {
    if (-not ($secrets -contains $name)) { $missing += $name }
  }
  if ($missing.Count -gt 0) {
    Write-Host ("{0}: MISSING -> {1}" -f $srv, ($missing -join ', ')) -ForegroundColor Yellow
  } else {
    Write-Host ("{0}: OK" -f $srv) -ForegroundColor Green
  }
}

# Filesystem allowlist
$config = docker mcp config read 2>$null
Write-Host "Config: $config" -ForegroundColor DarkGray
