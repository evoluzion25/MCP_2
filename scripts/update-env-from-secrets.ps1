param(
  [string]$EnvFile = "C:\\DevWorkspace\\credentials.env",
  [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

# Map MCP secret names to env var names
$map = @{
  'brave.api_key'          = 'BRAVE_API_KEY'
  'exa.api_key'            = 'EXA_API_KEY'
  'github-server.token'    = 'GITHUB_TOKEN'
}

function Add-EnvLine {
  param(
    [string]$Key,
    [string]$ValueHint = ''
  )
  if (-not (Test-Path $EnvFile)) {
    if ($DryRun) {
      Write-Host "[DRY-RUN] create env file: $EnvFile" -ForegroundColor Yellow
    } else {
      New-Item -ItemType File -Path $EnvFile -Force | Out-Null
    }
  }
  $existing = Select-String -Path $EnvFile -Pattern "^$Key=" -SimpleMatch -ErrorAction SilentlyContinue
  if (-not $existing) {
    $line = if ($ValueHint) { "$Key=$ValueHint" } else { "$Key=" }
    if ($DryRun) {
      Write-Host "[DRY-RUN] append to env: $line" -ForegroundColor Yellow
    } else {
      Add-Content -Path $EnvFile -Value $line
      Write-Host "Added key to env: $Key" -ForegroundColor Green
    }
  } else {
    Write-Host "Env already has key: $Key" -ForegroundColor DarkGray
  }
}

Write-Host "Reading MCP secret names..." -ForegroundColor Cyan
$secretNames = & docker mcp secret ls 2>$null | Where-Object { $_ -and (-not $_.StartsWith('NAME')) } | ForEach-Object { $_.Trim() }

if (-not $secretNames) {
  Write-Host "No secrets found in Docker MCP secret store." -ForegroundColor Yellow
}

# Build a reverse map for quick lookup
$knownSecretNames = $map.Keys
foreach ($name in $secretNames) {
  if ($knownSecretNames -contains $name) {
    $envKey = $map[$name]
    Add-EnvLine -Key $envKey
  }
}

# Also ensure keys from template are present even if secret not yet set
$allEnvKeys = $map.Values | Sort-Object -Unique
foreach ($envKey in $allEnvKeys) {
  Add-EnvLine -Key $envKey
}

Write-Host "Env backfill complete: $EnvFile" -ForegroundColor Cyan
