# Re-add ClickUp to docker-mcp.yaml
# This script adds ClickUp to the official Docker MCP catalog so it shows in Docker Desktop UI
# Run this after Docker updates the docker-mcp.yaml file

[CmdletBinding()]
param()

$catalogPath = "$env:USERPROFILE\.docker\mcp\catalogs\docker-mcp.yaml"
$backupPath = "$env:USERPROFILE\.docker\mcp\catalogs\docker-mcp.yaml.backup"

# Check if catalog exists
if (-not (Test-Path $catalogPath)) {
    Write-Error "Docker MCP catalog not found at: $catalogPath"
    exit 1
}

# Check if ClickUp already exists
$content = Get-Content $catalogPath -Raw
if ($content -match "(?m)^\s+clickup:\s*$") {
    Write-Host "✅ ClickUp already exists in docker-mcp.yaml" -ForegroundColor Green
    exit 0
}

Write-Host "🔄 Adding ClickUp to docker-mcp.yaml..." -ForegroundColor Cyan

# Create backup
Write-Host "📦 Creating backup..." -ForegroundColor Yellow
Copy-Item $catalogPath $backupPath -Force
Write-Host "✅ Backup created: $backupPath" -ForegroundColor Green

# Read the file
$lines = Get-Content $catalogPath

# Find the last entry (zerodha-kite) and add ClickUp after it
$clickupEntry = @"
  clickup:
    description: "Search, create, and retrieve tasks and documents, add comments, and track time through natural language commands. Comprehensive ClickUp integration for task management, time tracking, and document operations."
    title: "ClickUp"
    type: server
    dateAdded: "2025-10-18T00:00:00Z"
    image: mcp/clickup:1.12.0
    ref: ""
    readme: https://github.com/nsxdavid/clickup-mcp-server/blob/main/README.md
    source: https://github.com/nsxdavid/clickup-mcp-server
    upstream: https://www.npmjs.com/package/clickup-mcp-server
    tools:
      - name: getTaskById
      - name: addComment
      - name: updateTask
      - name: createTask
      - name: searchTasks
      - name: searchSpaces
      - name: getListInfo
      - name: updateListInfo
      - name: getTimeEntries
      - name: createTimeEntry
      - name: readDocument
      - name: searchDocuments
      - name: writeDocument
    prompts: 0
    resources: {}
    secrets:
      - name: clickup.api_key
        env: CLICKUP_API_TOKEN
        example: your-clickup-api-token
      - name: clickup.team_id
        env: CLICKUP_TEAM_ID
        example: your-team-id
    metadata:
      pulls: 0
      category: task-management
      tags:
        - clickup
        - task-management
        - project-management
        - productivity
        - time-tracking
        - documents
      license: ISC
      owner: nsxdavid
"@

# Find the last line with "owner: anshuljain90" (end of zerodha-kite entry)
$insertIndex = -1
for ($i = $lines.Count - 1; $i -ge 0; $i--) {
    if ($lines[$i] -match "^\s+owner:\s+anshuljain90\s*$") {
        $insertIndex = $i
        break
    }
}

if ($insertIndex -eq -1) {
    Write-Error "Could not find insertion point (zerodha-kite entry)"
    exit 1
}

# Insert ClickUp entry after zerodha-kite
$newLines = @()
$newLines += $lines[0..$insertIndex]
$newLines += $clickupEntry
$newLines += $lines[($insertIndex + 1)..($lines.Count - 1)]

# Write back to file
$newLines | Set-Content $catalogPath -Encoding UTF8

Write-Host "✅ ClickUp added to docker-mcp.yaml" -ForegroundColor Green

# Verify
$verifyContent = Get-Content $catalogPath -Raw
if ($verifyContent -match "(?m)^\s+clickup:\s*$") {
    Write-Host "✅ Verification successful - ClickUp is in the catalog" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Restart Docker Desktop to see ClickUp in the UI" -ForegroundColor White
    Write-Host "  2. Open Docker Desktop → Extensions → MCP" -ForegroundColor White
    Write-Host "  3. ClickUp should now appear in the server list" -ForegroundColor White
    Write-Host ""
    Write-Host "⚠️  Note: Run this script again after Docker updates docker-mcp.yaml" -ForegroundColor Yellow
} else {
    Write-Error "Verification failed - ClickUp was not added correctly"
    Write-Host "Restoring from backup..." -ForegroundColor Yellow
    Copy-Item $backupPath $catalogPath -Force
    exit 1
}
