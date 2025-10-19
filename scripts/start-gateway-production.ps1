<#
.SYNOPSIS
    Start MCP Gateway with production servers only

.DESCRIPTION
    Starts the MCP gateway serving only the production-servers catalog to avoid
    missing secret errors from the large official docker-mcp catalog.

.PARAMETER Port
    Port for the gateway (default: 3333)

.PARAMETER Transport
    Transport type: sse or stdio (default: sse)

.PARAMETER Verbose
    Enable verbose logging

.EXAMPLE
    .\start-gateway-production.ps1

.EXAMPLE
    .\start-gateway-production.ps1 -Verbose -Port 3000
#>

param(
    [int]$Port = 3333,
    [ValidateSet('sse', 'stdio')]
    [string]$Transport = 'sse',
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║        MCP Gateway - Production Servers Only                 ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Check if gateway is already running
$existing = docker ps --filter "name=mcp-gateway" --format "{{.Names}}" 2>$null
if ($existing) {
    Write-Host "⚠️  Gateway is already running. Stopping it first..." -ForegroundColor Yellow
    docker stop mcp-gateway 2>$null | Out-Null
    docker rm mcp-gateway 2>$null | Out-Null
    Start-Sleep -Seconds 2
}

Write-Host "Starting MCP Gateway..." -ForegroundColor Green
Write-Host "  Transport: $Transport" -ForegroundColor White
Write-Host "  Port: $Port" -ForegroundColor White
Write-Host "  Catalog: production-servers" -ForegroundColor White
Write-Host ""

# Build the command
$cmd = "docker mcp gateway run --transport $Transport --port $Port"

# Add verbose if requested
if ($Verbose) {
    $cmd += " --verbose"
}

Write-Host "Command: $cmd" -ForegroundColor DarkGray
Write-Host ""
Write-Host "🚀 Gateway starting..." -ForegroundColor Cyan
Write-Host ""
Write-Host "Available servers:" -ForegroundColor Yellow
Write-Host "  • brave-search (Brave Search API)" -ForegroundColor White
Write-Host "  • exa-search (Semantic search)" -ForegroundColor White
Write-Host "  • tavily-search (AI-powered search)" -ForegroundColor White
Write-Host "  • clickup-prod (Task management)" -ForegroundColor White
Write-Host "  • task-orchestrator-prod (Local tasks)" -ForegroundColor White
Write-Host "  • wikipedia (Reference)" -ForegroundColor White
Write-Host "  • github-prod (GitHub integration)" -ForegroundColor White
Write-Host "  • docker-management (Container management)" -ForegroundColor White
Write-Host "  • google-cloud-storage (GCS backup)" -ForegroundColor White
Write-Host "  • huggingface-prod (ML models/datasets)" -ForegroundColor White
Write-Host "  • cloudflare-api (DNS/tunnels)" -ForegroundColor White
Write-Host "  • runpod-management (GPU instances)" -ForegroundColor White
Write-Host "  • time-util (Time utilities)" -ForegroundColor White
Write-Host "  • youtube-transcripts (Video transcripts)" -ForegroundColor White
Write-Host ""
Write-Host "📡 Gateway will be available at:" -ForegroundColor Cyan
Write-Host "   http://localhost:$Port" -ForegroundColor White
Write-Host ""
Write-Host "Press Ctrl+C to stop the gateway" -ForegroundColor DarkGray
Write-Host ""

# Execute the command
Invoke-Expression $cmd
