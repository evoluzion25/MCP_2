$ErrorActionPreference='Stop'

function Install-App($id){
  if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw "winget not found. Install App Installer from Microsoft Store first."
  }
  winget install --id $id --accept-source-agreements --accept-package-agreements -h
}

try {
  Install-App -id 'Bitwarden.Bitwarden'
  Install-App -id 'Bitwarden.CLI'
  Write-Host "Bitwarden and CLI installed. Run: bw login; $(([char]36))env:BW_SESSION = (bw unlock --raw)" -ForegroundColor Green
} catch {
  Write-Error $_
}
$ErrorActionPreference='Stop'

function Test-AppInstalled($id){
  if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw "winget not found. Please update App Installer from Microsoft Store."
  }
  try {
    winget list --id $id --accept-source-agreements | Out-Null
    return $true
  } catch {
    return $false
  }
}

Write-Host "Installing Bitwarden App and CLI (if missing)..." -ForegroundColor Cyan

# Install desktop app (optional but helpful)
try { winget install --id Bitwarden.Bitwarden --silent --accept-package-agreements --accept-source-agreements } catch {}
# Install CLI
try { winget install --id Bitwarden.CLI --silent --accept-package-agreements --accept-source-agreements } catch {}

if (Get-Command bw -ErrorAction SilentlyContinue) {
  Write-Host "Bitwarden CLI installed." -ForegroundColor Green
} else {
  Write-Warning "Bitwarden CLI not detected. Run winget install Bitwarden.CLI manually."
}
