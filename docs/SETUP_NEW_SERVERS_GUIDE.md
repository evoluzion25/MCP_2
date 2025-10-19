# Setting Up Multiple MCP Servers via Docker Desktop Catalog

## Overview
This guide helps you set up multiple new MCP servers using Docker Desktop's MCP catalog system. The MCP_2 repository provides infrastructure-as-code for managing MCP servers.

## Current State Review

### Existing Catalogs
- **docker-mcp**: Official Docker MCP catalog (100+ servers available)
- **mcp2-service-templates**: Your custom service templates (OpenAI, Anthropic, ClickUp, Cloudflare, Hugging Face)
- **mcp2-services**: Custom services catalog

### Available Credentials (from credentials.env.template)
✅ **Ready to use:**
- `CLICKUP_API_KEY` + `CLICKUP_TEAM_ID`
- `EXA_API_KEY`
- `BRAVE_API_KEY`
- `HF_TOKEN` (Hugging Face)
- `CLOUDFLARE_API_KEY`
- `RUNPOD_API_KEY2` + related
- `GCS_ACCESS_KEY` + `GCS_SECRET_KEY` + `GCS_BUCKET`
- `RG_API_KEY` (vLLM server)

⚠️ **Empty (need to add if you want to use):**
- `OPENAI_API_KEY`
- `ANTHROPIC_API_KEY`
- `GEMINI_API_KEY`
- `PERPLEXITY_API_KEY`
- `DIGITALOCEAN_API_KEY`
- `HEROKU_API_KEY`
- `GODADDY_API_KEY`

## Quick Start: Add Popular Servers from Docker Catalog

### 1. Search-Related Servers

#### Brave Search (You have API key!)
```powershell
# View server details
docker mcp catalog show docker-mcp --format yaml | Select-String -Pattern "brave" -Context 20

# The brave server is already in the catalog, just need to set up secrets
docker mcp secret set brave.api_key
# Paste your key: BSAjKboJpJrVKmf8AMV87rCYyo3rowy
```

#### Exa Search (You have API key!)
```powershell
# Check if available
docker mcp catalog show docker-mcp --format yaml | Select-String -Pattern "exa" -Context 20

# Set up secret
docker mcp secret set exa.api_key
# Paste: 296048a9-6539-4352-957b-3370ed1b3fc2
```

#### Tavily Search
```powershell
# Already in catalog - need to get API key from https://tavily.com
docker mcp secret set tavily.api_token
```

### 2. Productivity & Task Management

#### ClickUp (You have credentials!)
```powershell
# Set up secrets
docker mcp secret set clickup.api_key
# Paste: pk_4234856_T5NJ7PUFZMPGN3KYMDSQIDX3XAO85O23

docker mcp secret set clickup.team_id
# Paste: 2218645
```

#### Task Orchestrator (No API key needed!)
```powershell
# This is a local database-backed task manager
# Already in docker-mcp catalog, no secrets needed
# Just start using it via the gateway
```

### 3. Development Tools

#### GitHub
```powershell
# Check for github server
docker mcp catalog show docker-mcp --format yaml | Select-String -Pattern "github" -Context 20

# Need GitHub personal access token
# Get from: https://github.com/settings/tokens
docker mcp secret set github.token
```

#### Docker
```powershell
# Manage Docker containers via MCP
docker mcp catalog show docker-mcp --format yaml | Select-String -Pattern "docker" -Context 10
```

### 4. Knowledge & Documentation

#### Wikipedia (No API key needed!)
```powershell
# Already in catalog: wikipedia-mcp
# No secrets required - ready to use!
```

#### Wolfram Alpha
```powershell
# Get API key from: https://products.wolframalpha.com/api
docker mcp secret set wolfram-alpha.api_key
```

### 5. Storage & File Systems

#### Filesystem (No API key needed!)
```powershell
# Already configured in mcp-config.yaml
# Provides access to:
# - C:\Users\ryan\Apps\GitHub
# - C:\DevWorkspace
```

#### Google Cloud Storage (You have credentials!)
```powershell
# Set up GCS access
docker mcp secret set gcs.access_key
# Paste: your-gcs-access-key-here

docker mcp secret set gcs.secret_key
# Paste: your-gcs-secret-key-here

docker mcp secret set gcs.bucket
# Paste: your-bucket-name
```

### 6. AI & ML Services

#### Hugging Face (You have token!)
```powershell
docker mcp secret set huggingface.token
# Paste: hf_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

## Step-by-Step: Set Up Multiple Servers

### Phase 1: Set Up Bitwarden Secret Management (RECOMMENDED)

**Why Bitwarden?**
- Centralized secret storage across all devices
- Encrypted vault with MFA protection
- Automatic sync to Docker MCP secrets
- No manual credential file management

```powershell
cd C:\DevWorkspace\MCP_2

# ONE-COMMAND SETUP (Recommended)
# This will:
# 1. Install Bitwarden CLI if needed
# 2. Login/unlock Bitwarden
# 3. Import all credentials from credentials.env to Bitwarden
# 4. Bootstrap Docker MCP secrets from Bitwarden
# 5. Verify setup
pwsh .\scripts\orchestrate-secrets.ps1 -EnvFile C:\DevWorkspace\credentials.env.template

# That's it! All your secrets are now:
# ✅ Stored securely in Bitwarden vault
# ✅ Synced to Docker MCP secrets
# ✅ Ready to use across all devices
```

**Manual Bitwarden Setup (if you prefer step-by-step):**

```powershell
# Step 1: Install Bitwarden CLI
pwsh .\scripts\install-bitwarden.ps1

# Step 2: Login and unlock
pwsh .\scripts\bitwarden-login.ps1
# Or manually:
# bw login
# $env:BW_SESSION = (bw unlock --raw)

# Step 3: Import credentials from env file to Bitwarden
pwsh .\scripts\bitwarden-import-env.ps1 -EnvFile C:\DevWorkspace\credentials.env.template -ItemName "MCP Secrets"

# Step 4: Bootstrap Docker MCP secrets from Bitwarden
pwsh .\scripts\bootstrap-machine.ps1 -Source bitwarden

# Step 5: Verify
pwsh .\scripts\check-readiness.ps1
```

This automatically sets up secrets for:
- ClickUp (API key + team ID)
- Brave Search
- Exa Search
- Hugging Face
- Cloudflare
- RunPod
- GCS

### Phase 1 Alternative: Direct Sync from credentials.env (Legacy)

If you don't want to use Bitwarden, you can still sync directly from the env file:

```powershell
cd C:\DevWorkspace\MCP_2

# Preview what will be synced (dry run)
pwsh .\scripts\sync-secrets.ps1 -DryRun

# Actually sync the secrets
pwsh .\scripts\sync-secrets.ps1
```

⚠️ **Note**: Direct sync requires manual credential file management on each device. Bitwarden is recommended for multi-device setups.

### Phase 2: Add Servers to Custom Catalog

Create a new comprehensive catalog file:

```powershell
# Edit or create a new catalog
code C:\DevWorkspace\MCP_2\catalogs\production-servers.yaml
```

**Example production-servers.yaml:**
```yaml
name: production-servers
displayName: Production MCP Servers
registry:
  # Search & Research
  brave-search:
    description: "Brave Search API for web search"
    title: "Brave Search"
    type: "server"
    image: "mcp/brave-search:latest"
    secrets:
      - name: "brave.api_key"
        env: "BRAVE_API_KEY"

  exa-search:
    description: "Exa semantic search"
    title: "Exa Search"
    type: "server"
    image: "mcp/exa:latest"
    secrets:
      - name: "exa.api_key"
        env: "EXA_API_KEY"

  tavily-search:
    description: "Tavily AI-powered search"
    title: "Tavily"
    type: "server"
    image: "mcp/tavily:latest"
    secrets:
      - name: "tavily.api_token"
        env: "TAVILY_API_KEY"

  # Task Management
  clickup-prod:
    description: "ClickUp task management"
    title: "ClickUp Production"
    type: "server"
    image: "mcp/clickup:latest"
    secrets:
      - name: "clickup.api_key"
        env: "CLICKUP_API_KEY"
      - name: "clickup.team_id"
        env: "CLICKUP_TEAM_ID"

  task-orchestrator:
    description: "Local task and feature management"
    title: "Task Orchestrator"
    type: "server"
    image: "ghcr.io/jpicklyk/task-orchestrator:latest"
    volumes:
      - mcp-task-data:/app/data

  # Knowledge & Reference
  wikipedia:
    description: "Wikipedia information retrieval"
    title: "Wikipedia"
    type: "server"
    image: "mcp/wikipedia-mcp:latest"

  # Development Tools
  github:
    description: "GitHub repository management"
    title: "GitHub"
    type: "server"
    image: "mcp/github:latest"
    secrets:
      - name: "github.token"
        env: "GITHUB_TOKEN"

  # Storage
  google-cloud-storage:
    description: "GCS backup system"
    title: "Google Cloud Storage"
    type: "server"
    image: "mcp/gcs:latest"
    secrets:
      - name: "gcs.access_key"
        env: "GCS_ACCESS_KEY"
      - name: "gcs.secret_key"
        env: "GCS_SECRET_KEY"
      - name: "gcs.bucket"
        env: "GCS_BUCKET"

  # AI/ML
  huggingface:
    description: "Hugging Face models and datasets"
    title: "Hugging Face"
    type: "server"
    image: "mcp/huggingface:latest"
    secrets:
      - name: "huggingface.token"
        env: "HF_TOKEN"
```

### Phase 3: Import and Activate

```powershell
# Import the new catalog
docker mcp catalog import C:\DevWorkspace\MCP_2\catalogs\production-servers.yaml

# Verify it was imported
docker mcp catalog ls

# Show the catalog
docker mcp catalog show production-servers --format yaml
```

### Phase 4: Start the Gateway

```powershell
# Start the gateway with all servers
docker mcp gateway run --transport sse --port 3333 --enable-all-servers --verbose

# Or use the startup script
pwsh C:\DevWorkspace\MCP_2\scripts\start-gateway.ps1
```

### Phase 5: Connect VS Code

```powershell
# Connect VS Code to the MCP gateway
docker mcp client connect vscode

# Restart VS Code if prompted
```

## Recommended Server Combinations by Use Case

### Legal Research & Document Work
```
- brave-search (web search)
- exa-search (semantic search)
- tavily-search (AI search)
- wikipedia (reference)
- google-cloud-storage (backup)
- clickup-prod (task management)
- filesystem (local files)
```

### Development Workflow
```
- github (repo management)
- task-orchestrator (feature tracking)
- clickup-prod (project management)
- filesystem (code access)
- docker (container management)
```

### AI/ML Projects
```
- huggingface (models/datasets)
- brave-search (research)
- github (code)
- google-cloud-storage (model storage)
```

## Automated Setup Script

Create a complete setup script that uses Bitwarden:

```powershell
# Save as: C:\DevWorkspace\MCP_2\scripts\setup-production-servers.ps1

Write-Host "=== MCP Production Servers Setup ===" -ForegroundColor Cyan

# Step 1: Set up Bitwarden and sync secrets
Write-Host "`n1. Setting up Bitwarden secret management..." -ForegroundColor Yellow
& "$PSScriptRoot\orchestrate-secrets.ps1" -EnvFile C:\DevWorkspace\credentials.env.template

# Step 2: Import production catalog
Write-Host "`n2. Importing production servers catalog..." -ForegroundColor Yellow
docker mcp catalog import "$PSScriptRoot\..\catalogs\production-servers.yaml"

# Step 3: Verify catalogs
Write-Host "`n3. Available catalogs:" -ForegroundColor Yellow
docker mcp catalog ls

# Step 4: Connect VS Code
Write-Host "`n4. Connecting VS Code client..." -ForegroundColor Yellow
docker mcp client connect vscode

Write-Host "`n✅ Setup complete! Restart VS Code to use the MCP servers." -ForegroundColor Green
Write-Host "`nTo start the gateway, run:" -ForegroundColor Cyan
Write-Host "  docker mcp gateway run --transport sse --port 3333 --enable-all-servers --verbose" -ForegroundColor White
```

**Usage:**
```powershell
# Full automated setup with Bitwarden
pwsh C:\DevWorkspace\MCP_2\scripts\setup-production-servers.ps1

# Or with dry-run to test first
pwsh C:\DevWorkspace\MCP_2\scripts\setup-production-servers.ps1 -DryRun
```

## Troubleshooting

### Check Gateway Status
```powershell
# View gateway logs
docker logs mcp-gateway

# Check if gateway is running
docker ps | Select-String mcp

# Test SSE endpoint
curl -skS http://127.0.0.1:3333/sse -H "Accept: text/event-stream" --max-time 5
```

### List All Secrets
```powershell
docker mcp secret list
```

### View Server Configuration
```powershell
# Show specific catalog
docker mcp catalog show production-servers --format yaml

# Show config in JSON
docker mcp config read
```

### Reset Everything
```powershell
# Stop gateway
docker mcp gateway stop

# Remove custom catalogs
docker mcp catalog reset

# Re-import
docker mcp catalog import C:\DevWorkspace\MCP_2\catalogs\production-servers.yaml
```

## Next Steps

1. **Get API Keys**: Sign up for services you want to use:
   - Tavily: https://tavily.com
   - OpenAI: https://platform.openai.com
   - Anthropic: https://console.anthropic.com
   - GitHub: https://github.com/settings/tokens

2. **Add to credentials.env**: Update your credentials file
   ```powershell
   code C:\DevWorkspace\credentials.env.template
   ```

3. **Sync Again**: Run sync-secrets.ps1 again after adding new keys

4. **Test Servers**: Use GitHub Copilot or Claude to test MCP tools:
   - "Search Brave for recent AI news"
   - "Get my ClickUp tasks"
   - "Search Wikipedia for quantum computing"

5. **Monitor Usage**: Check logs and metrics:
   ```powershell
   docker logs -f mcp-gateway
   ```

## Popular Servers from Docker Catalog to Consider

### No API Key Needed (Ready to Use)
- **wikipedia-mcp**: Search Wikipedia
- **time**: Time and timezone tools
- **task-orchestrator**: Local task management
- **filesystem**: File access (already configured)

### With Free API Keys
- **tavily**: AI search
- **github**: GitHub integration
- **slack**: Slack integration
- **notion**: Notion workspace

### Enterprise/Paid
- **anthropic**: Claude API
- **openai**: GPT models
- **perplexity**: Perplexity API
- **gemini**: Google Gemini

## Resources

- Docker MCP Docs: https://docs.docker.com/mcp/
- MCP Protocol: https://modelcontextprotocol.io
- Server Catalog: https://github.com/docker/mcp-gateway/blob/main/docs/catalog.md
- MCP_2 Repo: C:\DevWorkspace\MCP_2

---

**Last Updated**: October 18, 2025
**Author**: AI Agent for evoluzion25
**Repository**: dev-env-config + MCP_2
