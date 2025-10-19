param(
  [string]$EnvFile = 'C:\Users\ryan\Apps\GitHub\dev-env-config\credentials.env.template',
  [string]$ProjectId,
  [string]$ProjectName = 'MCP_2',
  [int]$DebounceMs = 800,
  [switch]$Bootstrap
)

$ErrorActionPreference='Stop'

function Write-Info($m){ Write-Host ("[watch] {0}" -f $m) -ForegroundColor Cyan }

if (-not (Test-Path $EnvFile)) { throw "Env file not found: $EnvFile" }
Write-Info "Watching: $EnvFile"

$fsw = New-Object System.IO.FileSystemWatcher
$fsw.Path = [System.IO.Path]::GetDirectoryName($EnvFile)
$fsw.Filter = [System.IO.Path]::GetFileName($EnvFile)
$fsw.IncludeSubdirectories = $false
$fsw.EnableRaisingEvents = $true

$timer = New-Object System.Timers.Timer($DebounceMs)
$timer.AutoReset = $false

$action = {
  $timer.Stop()
  $timer.Start()
}

$elapsed = {
  try {
    Write-Info 'Change detected → syncing to Bitwarden SM...'
    $argsList = @('-File', (Join-Path $PSScriptRoot 'sm-sync.ps1'), '-EnvFile', $EnvFile)
    if ($ProjectId) { $argsList += @('-ProjectId', $ProjectId) }
    if ($ProjectName) { $argsList += @('-ProjectName', $ProjectName) }
    if ($Bootstrap) { $argsList += '-Bootstrap' }
    pwsh -NoProfile @argsList | Out-Host
  } catch {
    Write-Info ("Sync error: {0}" -f $_.Exception.Message)
  }
}

Register-ObjectEvent $fsw Changed -Action $action | Out-Null
Register-ObjectEvent $fsw Created -Action $action | Out-Null
Register-ObjectEvent $fsw Renamed -Action $action | Out-Null
$timer.add_Elapsed($elapsed)

Write-Info 'Press Ctrl+C to stop...'
while ($true) { Start-Sleep -Seconds 1 }
