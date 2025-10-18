param(
  [switch]$Bootstrap,
  [switch]$ImportCustom,
  [switch]$AddGithub,
  [switch]$RunGateway,
  [switch]$ConnectVSCode
)

$ErrorActionPreference = 'Stop'

Write-Host "[MCP_2] Verifying Docker MCP CLI..." -ForegroundColor Cyan
& docker mcp version | Out-Null

Push-Location $PSScriptRoot\..

if ($Bootstrap) {
  Write-Host "[MCP_2] Bootstrapping starter catalog..." -ForegroundColor Cyan
  if (-not (Test-Path .\catalogs\starter.yaml)) {
    docker mcp catalog bootstrap .\catalogs\starter.yaml
  } else {
    Write-Host "starter.yaml already exists, skipping" -ForegroundColor Yellow
  }
}

if ($ImportCustom) {
  Write-Host "[MCP_2] Importing custom catalog..." -ForegroundColor Cyan
  docker mcp catalog import .\catalogs\custom_catalog.yaml
}

if ($AddGithub) {
  Write-Host "[MCP_2] Adding github-server from file into 'my-catalog'..." -ForegroundColor Cyan
  docker mcp catalog create my-catalog 2>$null | Out-Null
  docker mcp catalog add my-catalog github-server .\catalogs\github-server.yaml --force
}

if ($ConnectVSCode) {
  Write-Host "[MCP_2] Connecting VS Code client..." -ForegroundColor Cyan
  docker mcp client connect vscode
}

if ($RunGateway) {
  Write-Host "[MCP_2] Running gateway (Ctrl+C to stop)..." -ForegroundColor Cyan
  docker mcp gateway run
}

Pop-Location
