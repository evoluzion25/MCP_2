# Check if ClickUp exists in docker-mcp.yaml and add if missing
# Run this periodically or after Docker Desktop updates

[CmdletBinding()]
param(
    [switch]$AutoFix
)

$catalogPath = "$env:USERPROFILE\.docker\mcp\catalogs\docker-mcp.yaml"

# Check if catalog exists
if (-not (Test-Path $catalogPath)) {
    Write-Error "❌ Docker MCP catalog not found at: $catalogPath"
    exit 1
}

# Check if ClickUp exists
$content = Get-Content $catalogPath -Raw
if ($content -match "(?m)^\s+clickup:\s*$") {
    Write-Host "✅ ClickUp exists in docker-mcp.yaml" -ForegroundColor Green
    
    # Show when it was last modified
    $lastWrite = (Get-Item $catalogPath).LastWriteTime
    Write-Host "📅 Catalog last modified: $lastWrite" -ForegroundColor Cyan
    
    exit 0
} else {
    Write-Host "❌ ClickUp NOT found in docker-mcp.yaml" -ForegroundColor Red
    
    # Show when catalog was last modified (probably updated by Docker)
    $lastWrite = (Get-Item $catalogPath).LastWriteTime
    Write-Host "📅 Catalog last modified: $lastWrite" -ForegroundColor Yellow
    Write-Host "    (Docker may have updated the catalog)" -ForegroundColor Yellow
    Write-Host ""
    
    if ($AutoFix) {
        Write-Host "🔧 Auto-fix enabled, running add-clickup-to-catalog.ps1..." -ForegroundColor Cyan
        & "$PSScriptRoot\add-clickup-to-catalog.ps1"
    } else {
        Write-Host "💡 To add ClickUp back, run:" -ForegroundColor Cyan
        Write-Host "   pwsh .\scripts\add-clickup-to-catalog.ps1" -ForegroundColor White
        Write-Host ""
        Write-Host "   Or run with -AutoFix to automatically add it:" -ForegroundColor White
        Write-Host "   pwsh .\scripts\check-clickup-in-catalog.ps1 -AutoFix" -ForegroundColor White
    }
    
    exit 1
}
