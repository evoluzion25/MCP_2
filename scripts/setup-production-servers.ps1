<#
.SYNOPSIS
    Setup production MCP servers with Bitwarden secret management and catalog import

.DESCRIPTION
    This script automates the setup of production MCP servers by:
    1. Setting up Bitwarden for centralized secret management (recommended)
       - Or using legacy sync from credentials.env file
    2. Importing the production-servers catalog
    3. Verifying the setup
    4. Connecting VS Code client (optional)
    
    BITWARDEN INTEGRATION (Recommended):
    - Installs Bitwarden CLI if needed
    - Logs into your Bitwarden vault (one-time setup)
    - Imports all secrets from credentials.env to Bitwarden
    - Syncs secrets from Bitwarden to Docker MCP
    - Enables multi-device secret sync

.PARAMETER EnvFile
    Path to credentials.env file (default: C:\DevWorkspace\credentials.env.template)
    Used for initial Bitwarden import or legacy sync

.PARAMETER DryRun
    Preview changes without applying them

.PARAMETER SkipVSCode
    Skip VS Code client connection

.PARAMETER UseLegacySync
    Use direct sync from credentials.env instead of Bitwarden (not recommended)

.EXAMPLE
    .\setup-production-servers.ps1
    # Full setup with Bitwarden (recommended)
    
.EXAMPLE
    .\setup-production-servers.ps1 -DryRun
    # Preview what will happen without making changes
    
.EXAMPLE
    .\setup-production-servers.ps1 -SkipVSCode
    # Setup without connecting VS Code
    
.EXAMPLE
    .\setup-production-servers.ps1 -UseLegacySync
    # Use old method (direct env file sync, not recommended)
#>

param(
    [switch]$DryRun,
    [switch]$SkipVSCode,
    [switch]$UseLegacySync,
    [string]$EnvFile = "C:\DevWorkspace\credentials.env.template"
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir

# ============================================================================
# Helper Functions
# ============================================================================

function Write-Step {
    param([string]$Message)
    Write-Host "`n$Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor White
}

function Test-CommandExists {
    param([string]$Command)
    return $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

# ============================================================================
# Main Setup Process
# ============================================================================

Write-Host @"
╔══════════════════════════════════════════════════════════════════════════╗
║                                                                          ║
║              MCP PRODUCTION SERVERS SETUP                                ║
║              Bitwarden + Docker MCP Integration                          ║
║                                                                          ║
╚══════════════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

if ($DryRun) {
    Write-Warning "Running in DRY RUN mode - no changes will be made"
}

# ----------------------------------------------------------------------------
# Step 1: Verify Prerequisites
# ----------------------------------------------------------------------------

Write-Step "Step 1: Verifying prerequisites..."

if (-not (Test-CommandExists "docker")) {
    Write-Host "❌ Docker is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

$dockerVersion = docker version --format '{{.Server.Version}}' 2>$null
if (-not $dockerVersion) {
    Write-Host "❌ Docker daemon is not running" -ForegroundColor Red
    exit 1
}
Write-Info "Docker version: $dockerVersion"

# Check for Docker MCP
$mcpVersion = docker mcp version 2>$null
if (-not $mcpVersion) {
    Write-Warning "Docker MCP CLI not available - you may need Docker Desktop 28+"
    Write-Info "Continue anyway? (Y/N)"
    $response = Read-Host
    if ($response -ne 'Y') {
        exit 1
    }
} else {
    Write-Success "Docker MCP CLI available"
}

# Check credentials file
if (-not (Test-Path $EnvFile)) {
    Write-Warning "Credentials file not found: $EnvFile"
    Write-Info "Bitwarden sync can still work if you've already set up your vault"
    $EnvFile = $null
} else {
    Write-Success "Credentials file found: $EnvFile"
}

# ----------------------------------------------------------------------------
# Step 2: Set Up Secrets with Bitwarden (Recommended)
# ----------------------------------------------------------------------------

Write-Step "Step 2: Setting up secrets management..."

if ($UseLegacySync) {
    # Legacy: Direct sync from credentials.env
    Write-Info "Using legacy sync from credentials.env..."
    
    if ($EnvFile) {
        $syncScriptPath = Join-Path $ScriptDir "sync-secrets.ps1"
        if (Test-Path $syncScriptPath) {
            if ($DryRun) {
                Write-Info "Would run: & '$syncScriptPath' -DryRun"
                & $syncScriptPath -DryRun
            } else {
                Write-Info "Running sync-secrets.ps1..."
                & $syncScriptPath -EnvFile $EnvFile
            }
            Write-Success "Secret sync completed"
        } else {
            Write-Warning "sync-secrets.ps1 not found, skipping secret sync"
        }
    } else {
        Write-Warning "No credentials file available for legacy sync"
    }
} else {
    # Recommended: Bitwarden orchestration
    Write-Info "Using Bitwarden for centralized secret management..."
    Write-Info "This will:"
    Write-Host "  • Install Bitwarden CLI if needed" -ForegroundColor White
    Write-Host "  • Login/unlock your Bitwarden vault" -ForegroundColor White
    Write-Host "  • Import secrets from env file to Bitwarden" -ForegroundColor White
    Write-Host "  • Sync secrets to Docker MCP" -ForegroundColor White
    Write-Host "  • Verify setup" -ForegroundColor White
    Write-Host ""
    
    $orchestrateScript = Join-Path $ScriptDir "orchestrate-secrets.ps1"
    if (Test-Path $orchestrateScript) {
        if ($DryRun) {
            Write-Info "Would run Bitwarden orchestration..."
            Write-Info "Command: & '$orchestrateScript' -EnvFile '$EnvFile'"
        } else {
            Write-Info "Running Bitwarden orchestration..."
            try {
                if ($EnvFile) {
                    & $orchestrateScript -EnvFile $EnvFile
                } else {
                    & $orchestrateScript
                }
                Write-Success "Bitwarden secret management setup completed"
            } catch {
                Write-Warning "Bitwarden setup encountered an issue: $_"
                Write-Info "You can still proceed with the setup"
                Write-Info "To fix later, run: pwsh '$orchestrateScript' -EnvFile '$EnvFile'"
            }
        }
    } else {
        Write-Warning "orchestrate-secrets.ps1 not found"
        Write-Info "Falling back to legacy sync..."
        if ($EnvFile) {
            $syncScriptPath = Join-Path $ScriptDir "sync-secrets.ps1"
            if (Test-Path $syncScriptPath) {
                & $syncScriptPath -EnvFile $EnvFile
            }
        }
    }
}

# ----------------------------------------------------------------------------
# Step 3: Import Production Servers Catalog
# ----------------------------------------------------------------------------

Write-Step "Step 3: Importing production-servers catalog..."

$catalogPath = Join-Path $RepoRoot "catalogs\production-servers.yaml"
if (-not (Test-Path $catalogPath)) {
    Write-Host "❌ Catalog file not found: $catalogPath" -ForegroundColor Red
    exit 1
}

Write-Info "Catalog: $catalogPath"

if ($DryRun) {
    Write-Info "Would run: docker mcp catalog import $catalogPath"
    Write-Info "Catalog contents:"
    Get-Content $catalogPath | Select-Object -First 30
} else {
    try {
        docker mcp catalog import $catalogPath
        Write-Success "Catalog imported successfully"
    } catch {
        Write-Warning "Catalog import may have failed: $_"
        Write-Info "This might be OK if catalog already exists"
    }
}

# ----------------------------------------------------------------------------
# Step 4: Verify Catalogs
# ----------------------------------------------------------------------------

Write-Step "Step 4: Verifying available catalogs..."

if ($DryRun) {
    Write-Info "Would run: docker mcp catalog ls"
} else {
    Write-Info "Available catalogs:"
    docker mcp catalog ls
}

# ----------------------------------------------------------------------------
# Step 5: Show Available Servers
# ----------------------------------------------------------------------------

Write-Step "Step 5: Production servers available:"

$servers = @(
    "brave-search",
    "exa-search",
    "tavily-search",
    "clickup-prod",
    "task-orchestrator-prod",
    "wikipedia",
    "github-prod",
    "docker-management",
    "google-cloud-storage",
    "huggingface-prod",
    "cloudflare-api",
    "runpod-management",
    "time-util",
    "youtube-transcripts"
)

foreach ($server in $servers) {
    Write-Host "  • $server" -ForegroundColor White
}

# ----------------------------------------------------------------------------
# Step 6: Connect VS Code Client
# ----------------------------------------------------------------------------

if (-not $SkipVSCode -and -not $DryRun) {
    Write-Step "Step 6: Connecting VS Code client..."
    
    Write-Info "Do you want to connect VS Code to MCP? (Y/N)"
    $response = Read-Host
    
    if ($response -eq 'Y') {
        try {
            docker mcp client connect vscode
            Write-Success "VS Code client connected"
            Write-Warning "You may need to restart VS Code for changes to take effect"
        } catch {
            Write-Warning "Failed to connect VS Code: $_"
        }
    } else {
        Write-Info "Skipping VS Code connection"
    }
} else {
    Write-Step "Step 6: Skipping VS Code connection"
}

# ============================================================================
# Summary & Next Steps
# ============================================================================

Write-Host @"

╔══════════════════════════════════════════════════════════════════════════╗
║                         SETUP COMPLETE!                                  ║
╚══════════════════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Green

Write-Host "✨ Next Steps:" -ForegroundColor Cyan
Write-Host ""

if ($DryRun) {
    Write-Host "1. Run this script without -DryRun to apply changes" -ForegroundColor Yellow
    Write-Host "   .\setup-production-servers.ps1" -ForegroundColor White
} else {
    Write-Host "1. Start the MCP Gateway:" -ForegroundColor Yellow
    Write-Host "   docker mcp gateway run --transport sse --port 3333 --enable-all-servers --verbose" -ForegroundColor White
    Write-Host ""
    Write-Host "   Or use the startup script:" -ForegroundColor Yellow
    Write-Host "   pwsh .\scripts\start-gateway.ps1" -ForegroundColor White
    Write-Host ""
    Write-Host "2. If you connected VS Code, restart it now" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "3. Test MCP servers in GitHub Copilot or Claude:" -ForegroundColor Yellow
    Write-Host "   • 'Search Brave for AI news'" -ForegroundColor White
    Write-Host "   • 'Get my ClickUp tasks'" -ForegroundColor White
    Write-Host "   • 'Search Wikipedia for quantum computing'" -ForegroundColor White
    Write-Host ""
    Write-Host "4. View logs:" -ForegroundColor Yellow
    Write-Host "   docker logs -f mcp-gateway" -ForegroundColor White
    Write-Host ""
    Write-Host "5. Check gateway status:" -ForegroundColor Yellow
    Write-Host "   curl http://127.0.0.1:3333/health" -ForegroundColor White
}

Write-Host ""
Write-Host "📚 Documentation:" -ForegroundColor Cyan
Write-Host "   Setup Guide: $RepoRoot\docs\SETUP_NEW_SERVERS_GUIDE.md" -ForegroundColor White
Write-Host "   Catalog How-To: $RepoRoot\docs\catalog-howto.md" -ForegroundColor White
Write-Host ""

if (-not $DryRun) {
    Write-Host "🎉 Happy coding with MCP!" -ForegroundColor Green
}
