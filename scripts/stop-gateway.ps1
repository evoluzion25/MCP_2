$ErrorActionPreference = 'Stop'
$baseDir = Join-Path $env:LOCALAPPDATA 'Mcp'
$pidFile = Join-Path $baseDir 'gateway.pid'

if (-not (Test-Path $pidFile)) {
  Write-Host 'Gateway is not running (no pid file).' -ForegroundColor Yellow
  exit 0
}

$gwPid = Get-Content -Path $pidFile | Select-Object -First 1
if (-not $gwPid) {
  Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
  Write-Host 'Stale pid file removed.' -ForegroundColor Yellow
  exit 0
}

$proc = Get-Process -Id $gwPid -ErrorAction SilentlyContinue
if ($null -eq $proc) {
  Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
  Write-Host 'Process not found; cleaned up pid file.' -ForegroundColor Yellow
  exit 0
}

try {
  Stop-Process -Id $gwPid -Force -ErrorAction Stop
  Write-Host "Stopped gateway PID $gwPid" -ForegroundColor Green
} finally {
  Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
}
