#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Synchronizes enabled MCP servers from registry.yaml to docker-compose.yml

.DESCRIPTION
    Reads the list of enabled servers from Docker's MCP registry and updates
    the docker-compose.yml file to ensure all servers are included in the
    gateway's --servers command line argument.

.EXAMPLE
    .\sync-servers.ps1
    Syncs servers and updates docker-compose.yml

.EXAMPLE
    .\sync-servers.ps1 -DryRun
    Shows what would be changed without making modifications
#>

[CmdletBinding()]
param(
    [Parameter()]
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

# Paths
$registryPath = "$env:USERPROFILE\.docker\mcp\registry.yaml"
$dockerComposePath = "$PSScriptRoot\..\docker-compose.yml"

# Check if files exist
if (-not (Test-Path $registryPath)) {
    Write-Error "Registry file not found: $registryPath"
    exit 1
}

if (-not (Test-Path $dockerComposePath)) {
    Write-Error "docker-compose.yml not found: $dockerComposePath"
    exit 1
}

Write-Host "📋 Reading enabled servers from registry..." -ForegroundColor Cyan

# Read registry.yaml
$registryContent = Get-Content $registryPath -Raw
$servers = [System.Collections.Generic.List[string]]::new()

# Parse YAML manually (simple approach for this structure)
$registryContent -split "`n" | ForEach-Object {
    if ($_ -match '^\s+([a-z0-9\-_]+):\s*$') {
        $serverName = $Matches[1]
        if ($serverName -ne 'registry') {
            $servers.Add($serverName)
        }
    }
}

if ($servers.Count -eq 0) {
    Write-Warning "No servers found in registry"
    exit 0
}

# Sort servers alphabetically
$servers.Sort()
$serverList = $servers -join ','

Write-Host "✅ Found $($servers.Count) enabled servers:" -ForegroundColor Green
$servers | ForEach-Object { Write-Host "   - $_" -ForegroundColor Gray }

# Read docker-compose.yml
$composeContent = Get-Content $dockerComposePath -Raw

# Find current servers line using regex (handles long lines)
if ($composeContent -match '(?m)^(\s+- --servers=)([a-z0-9,\-_]+)') {
    $indent = $Matches[1]
    $currentServers = $Matches[2]
    $currentServerList = $currentServers -split ','
    
    Write-Host "`n📊 Current state:" -ForegroundColor Cyan
    Write-Host "   Servers in docker-compose.yml: $($currentServerList.Count)" -ForegroundColor Gray
    Write-Host "   Servers in registry.yaml: $($servers.Count)" -ForegroundColor Gray
    
    # Check for differences
    $missing = $servers | Where-Object { $_ -notin $currentServerList }
    $extra = $currentServerList | Where-Object { $_ -notin $servers }
    
    if ($missing.Count -gt 0) {
        Write-Host "`n➕ Servers to add:" -ForegroundColor Yellow
        $missing | ForEach-Object { Write-Host "   + $_" -ForegroundColor Yellow }
    }
    
    if ($extra.Count -gt 0) {
        Write-Host "`n➖ Servers to remove:" -ForegroundColor Red
        $extra | ForEach-Object { Write-Host "   - $_" -ForegroundColor Red }
    }
    
    if ($missing.Count -eq 0 -and $extra.Count -eq 0) {
        Write-Host "`n✅ docker-compose.yml is already in sync!" -ForegroundColor Green
        exit 0
    }
    
    if ($DryRun) {
        Write-Host "`n🔍 DRY RUN - No changes made" -ForegroundColor Magenta
        Write-Host "   New servers line would be:" -ForegroundColor Gray
        Write-Host "   $indent$serverList" -ForegroundColor Gray
        exit 0
    }
    
    # Create backup
    $backupPath = "$dockerComposePath.backup"
    Copy-Item $dockerComposePath $backupPath -Force
    Write-Host "`n💾 Created backup: $backupPath" -ForegroundColor Cyan
    
    # Update docker-compose.yml
    $newLine = "$indent$serverList"
    $oldLine = "$indent$currentServers"
    $newContent = $composeContent -replace [regex]::Escape($oldLine), $newLine
    
    Set-Content -Path $dockerComposePath -Value $newContent -NoNewline
    
    Write-Host "✅ Updated docker-compose.yml" -ForegroundColor Green
    Write-Host "`n📝 Next steps:" -ForegroundColor Cyan
    Write-Host "   1. Review the changes: git diff docker-compose.yml" -ForegroundColor Gray
    Write-Host "   2. Restart the gateway: docker compose restart mcp-gateway" -ForegroundColor Gray
    Write-Host "   3. Verify: docker logs mcp-gateway --tail 20" -ForegroundColor Gray
    
} else {
    Write-Error "Could not find --servers line in docker-compose.yml"
    exit 1
}
