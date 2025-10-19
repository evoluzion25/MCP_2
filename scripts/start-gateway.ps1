param(
    [int]$Port = 3333,
    [string]$Transport = 'sse',
    [string[]]$Servers = @('brave','exa','fetch','git','memory','playwright','sequentialthinking'),
    [switch]$BlockSecrets
)

$ErrorActionPreference = 'Stop'

# Directories for runtime artifacts
$baseDir = Join-Path $env:LOCALAPPDATA 'Mcp'
$null = New-Item -ItemType Directory -Path $baseDir -Force -ErrorAction SilentlyContinue
$logFile = Join-Path $baseDir 'gateway.log'
$pidFile = Join-Path $baseDir 'gateway.pid'

# If already running, bail out
if (Test-Path $pidFile) {
    try {
        $existingPid = Get-Content -Path $pidFile -ErrorAction Stop | Select-Object -First 1
        if ($existingPid -and (Get-Process -Id $existingPid -ErrorAction SilentlyContinue)) {
            Write-Host "Gateway already running with PID $existingPid" -ForegroundColor Yellow
            Write-Host "Log: $logFile"
            exit 0
        } else {
            Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
        }
    } catch {
        Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
    }
}

# Build server list and flags
$serversArg = $Servers -join ','
$blockSecretsFlag = if ($BlockSecrets.IsPresent) { '--block-secrets' } else { '--block-secrets=false' }

# Compose the docker mcp gateway command
$cmd = @(
    'docker mcp gateway run',
    "--transport $Transport",
    "--port $Port",
    "--servers $serversArg",
    '--verbose',
    $blockSecretsFlag
) -join ' '

# Start detached PowerShell that runs the gateway and pipes output to the log
$script = @'
$ErrorActionPreference = "Stop"
'@ + " `n" + $cmd + " *>> `"$logFile`""

# Ensure log rollover: append a header
"`n==== $(Get-Date -Format o) starting gateway: $cmd ====" | Out-File -FilePath $logFile -Append -Encoding UTF8

$p = Start-Process -FilePath pwsh -ArgumentList @('-NoLogo','-NoProfile','-Command', $script) -WindowStyle Hidden -PassThru
$p.Id | Out-File -FilePath $pidFile -Encoding ASCII -Force

Start-Sleep -Seconds 1

Write-Host "Gateway started (PID $($p.Id)) on port $Port" -ForegroundColor Green
Write-Host "Servers: $serversArg"
Write-Host "Log: $logFile"
