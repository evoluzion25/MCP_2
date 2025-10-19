param(
  [string]$TunnelId = '741d42fb-5a6a-47f6-9b67-47e95011f865'
)
$ErrorActionPreference = 'Stop'
$baseDir = Join-Path $env:LOCALAPPDATA 'Mcp'
$null = New-Item -ItemType Directory -Path $baseDir -Force -ErrorAction SilentlyContinue
$logFile = Join-Path $baseDir 'cloudflared.log'
$pidFile = Join-Path $baseDir 'cloudflared.pid'

if (Test-Path $pidFile) {
  $gwPid = Get-Content -Path $pidFile | Select-Object -First 1
  if ($gwPid -and (Get-Process -Id $gwPid -ErrorAction SilentlyContinue)) {
    Write-Host "Tunnel already running with PID $gwPid" -ForegroundColor Yellow
    Write-Host "Log: $logFile"
    exit 0
  } else { Remove-Item $pidFile -Force -ErrorAction SilentlyContinue }
}

"`n==== $(Get-Date -Format o) starting cloudflared tunnel $TunnelId ==== " | Out-File -FilePath $logFile -Append -Encoding UTF8

# Use explicit config path
$cfg = Join-Path $env:USERPROFILE '.cloudflared\config.yml'
$cmd = "cloudflared --config `"$cfg`" tunnel run $TunnelId"

$originCertPath = Join-Path $env:USERPROFILE '.cloudflared\\cert.pem'
$prelude = "`$env:TUNNEL_ORIGIN_CERT = (Get-Content `"$originCertPath`" -Raw); "
$p = Start-Process -FilePath pwsh -ArgumentList @('-NoLogo','-NoProfile','-Command', $prelude + "$cmd *>> `"$logFile`"") -WindowStyle Hidden -PassThru
$p.Id | Out-File -FilePath $pidFile -Encoding ASCII -Force
Start-Sleep -Seconds 2

Write-Host "Cloudflared started (PID $($p.Id))" -ForegroundColor Green
Write-Host "Log: $logFile"