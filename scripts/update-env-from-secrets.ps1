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
  'openai.api_key'         = 'OPENAI_API_KEY'
  'anthropic.api_key'      = 'ANTHROPIC_API_KEY'
  'gemini.api_key'         = 'GEMINI_API_KEY'
  'perplexity.api_key'     = 'PERPLEXITY_API_KEY'
  'cloudflare.api_key'     = 'CLOUDFLARE_API_KEY'
  'clickup.api_key'        = 'CLICKUP_API_KEY'
  'clickup.team_id'        = 'CLICKUP_TEAM_ID'
  'huggingface.token'      = 'HF_TOKEN'
  'rg.api_key'             = 'RG_API_KEY'
  'runpod.passkey'         = 'RUNPOD_PASSKEY'
  'runpod.api_key2'        = 'RUNPOD_API_KEY2'
  'runpod.s3_user'         = 'RUNPOD_S3_KEY2_USER'
  'runpod.s3_key'          = 'RUNPOD_S3_KEY2'
  'gcs.access_key'         = 'GCS_ACCESS_KEY'
  'gcs.secret_key'         = 'GCS_SECRET_KEY'
  'gcs.bucket'             = 'GCS_BUCKET'
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
