# MCP_2

Infrastructure-as-code for managing MCP servers via Docker Desktop, providing **dual access**:
- 🏠 **Local**: Claude Desktop, VS Code, Cursor (direct connection)
- 🌐 **Internet**: ChatGPT, external services (via Cloudflare Tunnel)

## 🌟 Key Features
- **Bitwarden Integration**: Centralized, encrypted secret management across all devices
- **Dual Access Architecture**: Local apps + Internet access via secure tunnel
- **Docker-Only**: No Node.js processes, no Windows services, single unified system
- **Official Catalog**: 100+ pre-configured MCP servers from Docker
- **Custom RG Catalog**: 1 custom server (ClickUp) - easily add more
- **Cloudflare Tunnel**: Secure internet access without open ports (ChatGPT integration)

## 🚀 Quick Start

### Production Setup with Docker Compose (Recommended)
```powershell
cd C:\DevWorkspace\MCP_2

# Start the complete stack (gateway + tunnel)
docker compose up -d

# Check status
docker compose ps

# View logs
docker compose logs -f
```

This starts:
- ✅ MCP Gateway (port 3333) - serves 100 tools from 9 servers
- ✅ Cloudflare Tunnel - exposes gateway to internet for ChatGPT
- ✅ Auto-restart on boot

**Active Servers**: 
- From docker-mcp (58 tools): brave-search, exa, fetch, git, memory, playwright, puppeteer, sequentialthinking
- From rg-mcp (42 tools): clickup

See **[Custom Server Installation Guide](docs/CUSTOM_SERVER_INSTALLATION_GUIDE.md)** for adding more custom servers.

See **[Docker Compose Architecture](docs/DOCKER_COMPOSE_ARCHITECTURE.md)** for full details.

### Alternative: Bitwarden Secret Management
```powershell
# Complete setup with Bitwarden secret management
pwsh .\scripts\orchestrate-secrets.ps1 -EnvFile C:\DevWorkspace\credentials.env.template
```

This single command:
- ✅ Installs Bitwarden CLI if needed
- ✅ Logs into your encrypted vault
- ✅ Imports all secrets securely
- ✅ Syncs to Docker MCP
- ✅ Verifies setup

### Alternative: Manual Setup
1. Ensure Docker Desktop v28+ with MCP CLI: `docker mcp version`
2. Connect VS Code client:
   - `docker mcp client connect vscode`
3. Bootstrap a starter catalog and view it:
   - `docker mcp catalog bootstrap ./catalogs/starter.yaml`
   - `docker mcp catalog show --format yaml`
4. Run the gateway (loads official + imported catalogs):
   - `docker mcp gateway run`

## 📚 Documentation

### Core Guides
- **[Docker Compose Architecture](docs/DOCKER_COMPOSE_ARCHITECTURE.md)** ⭐ - Production-ready setup (RECOMMENDED)
- **[Custom Server Installation](docs/CUSTOM_SERVER_INSTALLATION_GUIDE.md)** ⭐ - Complete guide to adding custom MCP servers
- **[Catalog Strategy](docs/CATALOG_STRATEGY.md)** ⭐ - Two-catalog system (official + custom)
- **[ClickUp UI Maintenance](docs/CLICKUP_UI_MAINTENANCE.md)** - Scripts to keep ClickUp visible in Docker Desktop UI
- **[Architecture Overview](docs/ARCHITECTURE.md)** - Local + Internet access architecture
- **[Bitwarden Setup Guide](docs/BITWARDEN_SETUP_GUIDE.md)** - Complete secret management setup
- **[Adding Custom Servers](docs/ADDING_CUSTOM_SERVERS.md)** - How to add servers to catalogs
- **[Client Configuration](docs/CLIENT_CONFIGURATION.md)** - Configure Claude, LM Studio, AnythingLLM
- **[Quick Reference](docs/QUICK_REFERENCE.md)** - Command cheat sheet

### External Resources
- Docker MCP Gateway docs: https://github.com/docker/mcp-gateway/blob/main/docs/mcp-gateway.md
- Docker MCP Catalog docs: https://github.com/docker/mcp-gateway/blob/main/docs/catalog.md
- Bitwarden CLI docs: https://bitwarden.com/help/cli/
- MCP Protocol: https://modelcontextprotocol.io

## 🔐 Secret Management with Bitwarden (Recommended)

### Why Bitwarden?
- ✅ **One source of truth** for all API keys across devices
- ✅ **Encrypted vault** with master password + optional 2FA
- ✅ **Automatic sync** - no manual credential file copying
- ✅ **Free** for personal use

### Setup
```powershell
# Install Bitwarden CLI
pwsh ./scripts/install-bitwarden.ps1

# Login and unlock (one-time per device)
pwsh ./scripts/bitwarden-login.ps1

# Import secrets from credentials.env to Bitwarden
pwsh ./scripts/bitwarden-import-env.ps1 -EnvFile C:\DevWorkspace\credentials.env.template

# Bootstrap Docker MCP secrets from Bitwarden
pwsh ./scripts/bootstrap-machine.ps1 -Source bitwarden

# Verify setup
pwsh ./scripts/check-readiness.ps1
```

### One-Shot Workflow (Recommended)
```powershell
# Does everything above in one command
pwsh ./scripts/orchestrate-secrets.ps1 -EnvFile C:\DevWorkspace\credentials.env.template
```

## 🔄 Legacy: Direct Sync from credentials.env

If you prefer not to use Bitwarden (not recommended for multi-device setups):

```powershell
# Sync secrets directly from credentials.env file
pwsh ./scripts/sync-secrets.ps1

# Keep env file current with discovered secrets
pwsh ./scripts/update-env-from-secrets.ps1
```

**Note**: This requires manually managing credentials.env on each device.

## 📦 Supported Secrets

All mapped in `secrets/manifest.yaml`:

### Search & Research
- `BRAVE_API_KEY`, `EXA_API_KEY`

### Task Management  
- `CLICKUP_API_KEY`, `CLICKUP_TEAM_ID` (see [Catalog Strategy](docs/CATALOG_STRATEGY.md))

### AI Services
- `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GEMINI_API_KEY`, `PERPLEXITY_API_KEY`, `HF_TOKEN`

### Infrastructure
- `CLOUDFLARE_API_KEY`, `RUNPOD_API_KEY2`, `RUNPOD_S3_KEY2`, `GCS_ACCESS_KEY`, `GCS_SECRET_KEY`

### Development
- `GITHUB_TOKEN`, `RG_API_KEY`

And more... see [manifest.yaml](secrets/manifest.yaml) for complete list.

## 🔌 Production MCP Servers

The gateway uses a **two-catalog strategy**:
1. **docker-mcp** - Official catalog (100+ servers, read-only)
2. **rg-mcp** - Custom catalog (your additions)

See **[Custom Server Installation Guide](docs/CUSTOM_SERVER_INSTALLATION_GUIDE.md)** for complete instructions on adding servers.

### Active Servers in Gateway

**From docker-mcp** (8 servers, 58 tools):
- brave-search, exa, fetch, git, memory, playwright, puppeteer, sequentialthinking

**From rg-mcp** (1 server, 42 tools):
- clickup (see [ClickUp Installation](docs/CLICKUP_INSTALLATION_COMPLETE.md))

**Total**: 9 servers, 100 tools

### production-verified (Legacy Reference)
Uses real Docker images with SHA256 hashes from official catalog:

```powershell
# Import verified production catalog
docker mcp catalog import .\catalogs\production-verified.yaml

# Verify import
docker mcp catalog show production-verified
```

**Servers Included**:
- **brave-search**: Web search with Brave API
- **github**: GitHub repository management  
- **time**: Time and timezone utilities
- **wikipedia**: Wikipedia article search

### Legacy: production-servers
Contains 14 servers but uses placeholder images (for reference only):

**Available Servers**:
- **Search**: Brave, Exa, Tavily, Wikipedia
- **Tasks**: ClickUp, Task Orchestrator
- **AI/ML**: Hugging Face
- **DevOps**: GitHub, Docker, Cloudflare, RunPod
- **Storage**: Google Cloud Storage
- **Utils**: Time, YouTube Transcripts

See [production-servers.yaml](catalogs/production-servers.yaml) for details.

## 🛠️ Service Templates

```powershell
# Import template catalog with common services
docker mcp catalog import .\catalogs\service-templates.yaml
```

Pre-wired placeholders for:
- OpenAI, Anthropic
- ClickUp, Cloudflare
- Hugging Face

## 📋 Scripts Reference

### Bitwarden Workflows
- `orchestrate-secrets.ps1` - Complete Bitwarden setup in one command ⭐
- `bitwarden-login.ps1` - Login and unlock vault
- `bitwarden-import-env.ps1` - Import env file to Bitwarden
- `bootstrap-machine.ps1` - Sync Bitwarden → Docker MCP
- `install-bitwarden.ps1` - Install Bitwarden CLI

### Gateway Management
- `start-gateway.ps1` - Start MCP gateway
- `stop-gateway.ps1` - Stop MCP gateway  
- `status-gateway.ps1` - Check gateway status

### Setup & Deployment
- `setup-production-servers.ps1` - Full production setup with Bitwarden
- `check-readiness.ps1` - Verify secret configuration

### Legacy (Direct Sync)
- `sync-secrets.ps1` - Direct credentials.env → Docker MCP
- `update-env-from-secrets.ps1` - Update env template from secrets

## 🔗 Multi-Device Setup

### First Device (Primary)
```powershell
# Full setup with env file
pwsh .\scripts\orchestrate-secrets.ps1 -EnvFile C:\DevWorkspace\credentials.env.template
```

### Additional Devices (No env file needed!)
```powershell
# 1. Install Bitwarden
pwsh .\scripts\install-bitwarden.ps1

# 2. Login (vault already has all secrets)
pwsh .\scripts\bitwarden-login.ps1

# 3. Bootstrap from Bitwarden
pwsh .\scripts\bootstrap-machine.ps1 -Source bitwarden

# Done! All secrets synced from your vault
```

## 🎯 Example Workflows

### Legal Research
```
Active servers:
- Brave Search (web search)
- Exa (semantic search)
- Wikipedia (reference)
- Google Cloud Storage (backup)
- ClickUp (task tracking)
```

### Development
```
Active servers:
- GitHub (repos & issues)
- Task Orchestrator (feature tracking)
- Docker (container management)
- Filesystem (code access)
```

### AI/ML Projects
```
Active servers:
- Hugging Face (models/datasets)
- RunPod (GPU instances)
- Google Cloud Storage (model storage)
```

## 📖 Documentation

⭐ **[IMPLEMENTATION SUMMARY](IMPLEMENTATION_SUMMARY.md)** - Complete tech stack, architecture & all issues resolved  
⭐ **[UPDATES LOG](UPDATES_LOG.md)** - All verified facts and corrections (October 18, 2025)

### Core Guides
- **[Docker Compose Architecture](docs/DOCKER_COMPOSE_ARCHITECTURE.md)** - Production setup guide (Recommended) ⭐
- **[Custom Server Installation](docs/CUSTOM_SERVER_INSTALLATION_GUIDE.md)** - Adding custom MCP servers ⭐
- **[Catalog Strategy](docs/CATALOG_STRATEGY.md)** - Two-catalog system & adding custom servers ⭐
- **[MCP Server Architecture](docs/MCP_SERVER_ARCHITECTURE.md)** - Understanding ephemeral containers
- **[Bitwarden Setup Guide](docs/BITWARDEN_SETUP_GUIDE.md)** - Complete secret management setup
- **[Client Configuration](docs/CLIENT_CONFIGURATION.md)** - LM Studio, AnythingLLM, Claude setup
- **[Complete Cleanup Report](docs/COMPLETE_CLEANUP_REPORT.md)** - What was removed & why
- **[Gateway Tunnel Fix](docs/GATEWAY_TUNNEL_FIX.md)** - 502 error resolution guide
- **[Adding Custom Servers](docs/ADDING_CUSTOM_SERVERS.md)** - How to add servers to catalogs
- **[Adding ClickUp Server](docs/ADDING_CLICKUP_SERVER.md)** - ClickUp setup example
- **[ClickUp Installation Complete](docs/CLICKUP_INSTALLATION_COMPLETE.md)** - ClickUp verification checklist
- **[Setup New Servers](docs/SETUP_NEW_SERVERS_GUIDE.md)** - Production server configuration
- **[Quick Reference](docs/QUICK_REFERENCE.md)** - Command cheat sheet
- **[Toolkit UI Setup](docs/TOOLKIT_UI_SETUP.md)** - Troubleshooting Docker Desktop UI

### External Resources
- Docker MCP Catalog docs: https://github.com/docker/mcp-gateway/blob/main/docs/catalog.md
- Bitwarden CLI docs: https://bitwarden.com/help/cli/
- MCP Protocol: https://modelcontextprotocol.io
- CLI reference: https://docs.docker.com/reference/cli/docker/mcp/

## 🔒 Security Notes

- Keep `credentials.env` PRIVATE (git-ignored template only)
- Use Bitwarden for secret storage (encrypted vault)
- Enable 2FA on Bitwarden account
- Rotate keys regularly
- Never commit real secrets to git

---

**Getting Started**: See [BITWARDEN_SETUP_GUIDE.md](docs/BITWARDEN_SETUP_GUIDE.md) for complete setup instructions.
