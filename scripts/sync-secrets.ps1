param(
  [string]$EnvFile = "C:\\DevWorkspace\\credentials.env",
  [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

function Set-McpSecret {
  param(
    [Parameter(Mandatory=$true)][string]$Name,
    [Parameter(Mandatory=$true)][string]$Value
  )
  if ($DryRun) {
    Write-Host "[DRY-RUN] docker mcp secret set $Name ****" -ForegroundColor Yellow
  } else {
    $p = Start-Process -FilePath "docker" -ArgumentList @("mcp","secret","set",$Name,"--value",$Value) -NoNewWindow -PassThru -Wait -RedirectStandardOutput stdout.txt -RedirectStandardError stderr.txt
    if ($p.ExitCode -ne 0) {
      $stderr = Get-Content -Raw -Path "./stderr.txt"
      Write-Warning ("Failed to set secret {0}: {1}" -f $Name, $stderr)
    } else {
      Write-Host "Set secret $Name" -ForegroundColor Green
    }
    Remove-Item -ErrorAction SilentlyContinue stdout.txt, stderr.txt
  }
}

if (-not (Test-Path $EnvFile)) {
  Write-Error "Env file not found: $EnvFile"
  exit 1
}

Write-Host "Loading env from $EnvFile" -ForegroundColor Cyan
Get-Content $EnvFile | ForEach-Object {
  $line = $_.Trim()
  if (-not $line -or $line.StartsWith('#')) { return }
  $kv = $line -split '=',2
  if ($kv.Count -ne 2) { return }
  $key = $kv[0].Trim()
  $val = $kv[1].Trim()

  switch ($key) {
    'BRAVE_API_KEY'       { Set-McpSecret -Name 'brave.api_key' -Value $val }
    'EXA_API_KEY'         { Set-McpSecret -Name 'exa.api_key' -Value $val }
    'GITHUB_TOKEN'        { Set-McpSecret -Name 'github-server.token' -Value $val }
    default               { Write-Host "Unmapped env key: $key (skipping)" -ForegroundColor DarkGray }
  }
}

Write-Host "Done syncing secrets." -ForegroundColor Cyan
