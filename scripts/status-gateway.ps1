$baseDir = Join-Path $env:LOCALAPPDATA 'Mcp'
$pidFile = Join-Path $baseDir 'gateway.pid'
$logFile = Join-Path $baseDir 'gateway.log'

if (Test-Path $pidFile) {
  $gwPid = Get-Content -Path $pidFile | Select-Object -First 1
  if ($gwPid -and (Get-Process -Id $gwPid -ErrorAction SilentlyContinue)) {
    Write-Host "Gateway running (PID $gwPid)" -ForegroundColor Green
  } else {
    Write-Host 'Gateway pid file exists but process is not running.' -ForegroundColor Yellow
  }
} else {
  Write-Host 'Gateway is not running.' -ForegroundColor Yellow
}

if (Test-Path $logFile) {
  Write-Host "Log tail:" -ForegroundColor Cyan
  Get-Content -Path $logFile -Tail 20
}
