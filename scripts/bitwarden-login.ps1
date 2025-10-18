$ErrorActionPreference = 'Stop'

Write-Host "Bitwarden CLI login starting..." -ForegroundColor Cyan
& bw login
if ($LASTEXITCODE -ne 0) {
  Write-Error "Bitwarden login failed. Please check your email/password or use --apikey mode."
}

Write-Host "Unlocking vault to obtain session token..." -ForegroundColor Cyan
$session = & bw unlock --raw
if ($LASTEXITCODE -ne 0 -or -not $session) {
  Write-Error "Bitwarden unlock failed. Run 'bw unlock' manually and set $env:BW_SESSION."; exit 1
}

$env:BW_SESSION = $session
Write-Host "BW_SESSION set for this shell session." -ForegroundColor Green
Write-Host "Note: You'll need to unlock again in new shells: $env:BW_SESSION = (bw unlock --raw)" -ForegroundColor DarkGray
