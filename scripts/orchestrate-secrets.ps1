$ErrorActionPreference = 'Stop'

param(
  [string]$EnvFile,
  [string]$ItemName = 'MCP Secrets'
)

function Write-Section($text){ Write-Host "`n=== $text ===" -ForegroundColor Cyan }

function Resolve-EnvFile{
  param([string]$Path)
  if ($Path) { return $Path }
  $candidates = @(
    'C:\DevWorkspace\credentials.env',
    'C:\Users\ryan\Apps\GitHub\dev-env-config\credentials.env',
    'C:\DevWorkspace\credentials.env.template',
    'C:\Users\ryan\Apps\GitHub\dev-env-config\credentials.env.template'
  )
  foreach($p in $candidates){ if (Test-Path $p) { return $p } }
  throw 'Env file not found. Pass -EnvFile explicitly.'
}

function Initialize-Bitwarden{
  if (Get-Command bw -ErrorAction SilentlyContinue) { return }
  Write-Section 'Installing Bitwarden CLI (and Desktop)'
  pwsh -File "$PSScriptRoot\install-bitwarden.ps1"
}

function Connect-BitwardenSession{
  Write-Section 'Bitwarden login/unlock'
  $statusRaw = bw status 2>$null
  $status = $null
  if ($LASTEXITCODE -eq 0 -and $statusRaw) { $status = $statusRaw | ConvertFrom-Json }

  if (-not $status -or $status.status -eq 'unauthenticated') {
    Write-Host 'You are not logged in. Launching bw login (interactive)...' -ForegroundColor Yellow
    & bw login
    if ($LASTEXITCODE -ne 0) { throw 'Bitwarden login failed.' }
  }

  # Always attempt to unlock to obtain a fresh session key
  $session = (& bw unlock --raw)
  if ($LASTEXITCODE -ne 0 -or -not $session) { throw 'Bitwarden unlock failed. Cannot obtain session key.' }
  $env:BW_SESSION = $session
  Write-Host 'Bitwarden session established.' -ForegroundColor Green
}

$envPath = Resolve-EnvFile -Path $EnvFile
Write-Host "Using env file: $envPath" -ForegroundColor Green

Initialize-Bitwarden
Connect-BitwardenSession

Write-Section 'Importing env -> Bitwarden item fields'
pwsh -File "$PSScriptRoot\bitwarden-import-env.ps1" -EnvFile $envPath -ItemName $ItemName

Write-Section 'Bootstrapping MCP secrets from Bitwarden'
pwsh -File "$PSScriptRoot\bootstrap-machine.ps1" -Source bitwarden

Write-Section 'Readiness check'
pwsh -File "$PSScriptRoot\check-readiness.ps1"

Write-Host "`nAll done. If some secrets are still missing, update the env file or Bitwarden item '$ItemName' and rerun this script." -ForegroundColor Yellow
