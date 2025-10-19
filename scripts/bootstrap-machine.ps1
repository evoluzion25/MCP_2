param(
  [ValidateSet('bitwarden','env')]$Source='env',
  [string]$EnvFile = "C:\\DevWorkspace\\credentials.env",
  [switch]$DryRun
)

$ErrorActionPreference='Stop'

function Get-Manifest {
  $jsonPath = Join-Path $PSScriptRoot '..' 'secrets' 'manifest.json'
  $yamlPath = Join-Path $PSScriptRoot '..' 'secrets' 'manifest.yaml'
  if (Test-Path $jsonPath) {
    return (Get-Content $jsonPath -Raw) | ConvertFrom-Json
  }
  if (Test-Path $yamlPath) {
    $text = Get-Content $yamlPath -Raw
    if (Get-Command ConvertFrom-Yaml -ErrorAction SilentlyContinue) {
      return $text | ConvertFrom-Yaml
    } else {
      throw "ConvertFrom-Yaml not available. Install 'powershell-yaml' (Install-Module powershell-yaml) or provide secrets/manifest.json"
    }
  }
  throw "No manifest found. Expected: $jsonPath or $yamlPath"
}

$mf = Get-Manifest

# Load key->value from provider
$kv = @{}
switch ($Source) {
  'env' {
    if (-not (Test-Path $EnvFile)) { throw "Env file not found: $EnvFile" }
    Get-Content $EnvFile | ForEach-Object {
      $line = $_.Trim(); if (-not $line -or $line.StartsWith('#')) { return }
      $sp = $line -split '=',2; if ($sp.Count -ne 2) { return }
      $key = $sp[0].Trim()
      $val = $sp[1].Trim()
      # Trim surrounding quotes if present
      if ($val.StartsWith('"') -and $val.EndsWith('"')) { $val = $val.Trim('"') }
      $kv[$key] = $val
    }
  }
  'bitwarden' {
    if (-not (Get-Command bw -ErrorAction SilentlyContinue)) {
      throw "Bitwarden CLI 'bw' not found. Install from https://bitwarden.com/help/cli/ or use -Source env"
    }
    # Ensure BW session is unlocked or bw commands will fail silently
    if (-not $env:BW_SESSION) {
      Write-Warning "BW_SESSION not set. Run: bw login; $(([char]36))env:BW_SESSION = (bw unlock --raw)"
    }
    $json = & (Join-Path $PSScriptRoot 'providers' 'bitwarden.ps1')
    $kv = $json | ConvertFrom-Json
  }
}

function Set-McpSecret {
  param([string]$Name,[string]$Value)
  if ($DryRun) { Write-Host "[DRY-RUN] set $Name" -ForegroundColor Yellow; return }
  # docker mcp secret set expects key[=value] form
  docker mcp secret set "$Name=$Value" | Out-Null
}

# Apply per manifest
$keys = $mf.keys.PSObject.Properties | ForEach-Object { $_.Name }
foreach ($k in $keys) {
  $m = $mf.keys.$k
  $mcp = $m.mcp
  if ($kv.ContainsKey($k) -and $kv[$k]) {
    Set-McpSecret -Name $mcp -Value $kv[$k]
  } else {
    Write-Host "Missing value for $k (maps to $mcp)" -ForegroundColor DarkGray
  }
}

Write-Host "Bootstrap complete." -ForegroundColor Cyan
