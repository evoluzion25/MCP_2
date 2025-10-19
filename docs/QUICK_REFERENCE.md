# MCP Servers Quick Reference Card

## 🚀 Quick Start with Bitwarden (Recommended)

```powershell
cd C:\DevWorkspace\MCP_2

# ONE COMMAND - Complete setup with Bitwarden
pwsh .\scripts\orchestrate-secrets.ps1 -EnvFile C:\DevWorkspace\credentials.env.template

# That's it! All secrets are now:
# ✅ Stored in encrypted Bitwarden vault
# ✅ Synced to Docker MCP
# ✅ Ready across all devices
```

## 🔐 Secret Management Commands

### Bitwarden (Recommended)
```powershell
# Complete setup (first time)
pwsh .\scripts\orchestrate-secrets.ps1 -EnvFile C:\DevWorkspace\credentials.env.template

# Daily use (after PowerShell restart)
$env:BW_SESSION = (bw unlock --raw)

# New device sync (no env file needed!)
pwsh .\scripts\bootstrap-machine.ps1 -Source bitwarden

# Update secrets in Bitwarden, then re-sync
pwsh .\scripts\bootstrap-machine.ps1 -Source bitwarden
```

### Legacy (Direct Sync - Not Recommended)
```powershell
# Sync from credentials.env directly
pwsh .\scripts\sync-secrets.ps1 -EnvFile C:\DevWorkspace\credentials.env.template
```

## Ready to Use (Have Credentials)

### 🔍 Search & Research
| Server | Purpose | API Key Status | Key Name |
|--------|---------|---------------|----------|
| **Brave Search** | Privacy-focused web search | ✅ Have key | `brave.api_key` |
| **Exa Search** | Semantic search | ✅ Have key | `exa.api_key` |
| **Wikipedia** | Reference lookup | ✅ No key needed | - |
| **Tavily** | AI-powered search | ❌ Need key | `tavily.api_token` |

### ✅ Task Management
| Server | Purpose | API Key Status | Key Name |
|--------|---------|---------------|----------|
| **ClickUp** | Project management | ✅ Have keys | `clickup.api_key` + `clickup.team_id` |
| **Task Orchestrator** | Local task DB | ✅ No key needed | - |

### 💾 Storage & Backup
| Server | Purpose | API Key Status | Key Name |
|--------|---------|---------------|----------|
| **GCS** | Google Cloud Storage backup | ✅ Have keys | `gcs.access_key` + `gcs.secret_key` |
| **Filesystem** | Local file access | ✅ No key needed | - |

### 🤖 AI & ML
| Server | Purpose | API Key Status | Key Name |
|--------|---------|---------------|----------|
| **Hugging Face** | Models & datasets | ✅ Have token | `huggingface.token` |
| **OpenAI** | GPT models | ❌ Need key | `openai.api_key` |
| **Anthropic** | Claude API | ❌ Need key | `anthropic.api_key` |

### 🛠️ DevOps & Infrastructure
| Server | Purpose | API Key Status | Key Name |
|--------|---------|---------------|----------|
| **Cloudflare** | DNS, tunnels, edge | ✅ Have key | `cloudflare.api_key` |
| **RunPod** | GPU instances | ✅ Have keys | `runpod.api_key` + `runpod.s3_key` |
| **GitHub** | Repo management | ❌ Need token | `github.token` |
| **Docker** | Container management | ✅ No key needed | - |

### 🔧 Utilities
| Server | Purpose | API Key Status | Key Name |
|--------|---------|---------------|----------|
| **Time** | Time/timezone tools | ✅ No key needed | - |
| **YouTube Transcripts** | Video transcriptions | ✅ No key needed | - |

## Quick Setup Commands

### 1. Complete Setup with Bitwarden (⭐ Recommended)
```powershell
cd C:\DevWorkspace\MCP_2

# All-in-one setup
pwsh .\scripts\setup-production-servers.ps1

# Or step by step:
# a) Setup secrets with Bitwarden
pwsh .\scripts\orchestrate-secrets.ps1 -EnvFile C:\DevWorkspace\credentials.env.template

# b) Import production servers
docker mcp catalog import .\catalogs\production-servers.yaml

# c) Start gateway
docker mcp gateway run --transport sse --port 3333 --enable-all-servers

# d) Connect VS Code
docker mcp client connect vscode
```

### 2. Legacy Setup (Direct Sync)
```powershell
# Use if you don't want Bitwarden
pwsh .\scripts\setup-production-servers.ps1 -UseLegacySync
```
```powershell
# ClickUp
docker mcp secret set clickup.api_key
# Paste: pk_4234856_T5NJ7PUFZMPGN3KYMDSQIDX3XAO85O23

docker mcp secret set clickup.team_id
# Paste: 2218645

# Brave Search
docker mcp secret set brave.api_key
# Paste: BSAjKboJpJrVKmf8AMV87rCYyo3rowy

# Exa Search
docker mcp secret set exa.api_key
# Paste: your-clickup-api-key-here

# Hugging Face
docker mcp secret set huggingface.token
# Paste: hf_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# GCS
docker mcp secret set gcs.access_key
docker mcp secret set gcs.secret_key

# Cloudflare
docker mcp secret set cloudflare.api_key
# Paste: 07dd3afe7e878469dc2ca27dcd98489ae0102

# RunPod
docker mcp secret set runpod.api_key
docker mcp secret set runpod.s3_key
```

### 3. Start Gateway
```powershell
# Option A: Direct command
docker mcp gateway run --transport sse --port 3333 --enable-all-servers --verbose

# Option B: Use script
pwsh C:\DevWorkspace\MCP_2\scripts\start-gateway.ps1
```

### 4. Connect VS Code
```powershell
docker mcp client connect vscode
# Then restart VS Code
```

## Gateway Management

### Start/Stop
```powershell
# Start
docker mcp gateway run --transport sse --port 3333 --enable-all-servers

# Stop
docker mcp gateway stop

# Check status
docker ps | Select-String mcp
```

### View Logs
```powershell
# Follow logs
docker logs -f mcp-gateway

# Last 50 lines
docker logs --tail 50 mcp-gateway
```

### Test Connectivity
```powershell
# Health check
curl http://127.0.0.1:3333/health

# SSE endpoint
curl -skS http://127.0.0.1:3333/sse -H "Accept: text/event-stream" --max-time 5
```

## Catalog Management

### List Catalogs
```powershell
docker mcp catalog ls
```

### Show Catalog Contents
```powershell
# Production servers
docker mcp catalog show production-servers --format yaml

# Official Docker catalog
docker mcp catalog show docker-mcp --format yaml

# Service templates
docker mcp catalog show mcp2-service-templates --format yaml
```

### Import/Update Catalog
```powershell
# Import new catalog
docker mcp catalog import C:\DevWorkspace\MCP_2\catalogs\production-servers.yaml

# Force overwrite
docker mcp catalog import --force C:\DevWorkspace\MCP_2\catalogs\production-servers.yaml
```

### Add Server to Catalog
```powershell
docker mcp catalog add production-servers my-server ./server-config.yaml
```

## Secret Management

### List All Secrets
```powershell
docker mcp secret list
```

### Set Secret
```powershell
# Interactive (secure)
docker mcp secret set <secret-name>

# From environment variable
docker mcp secret set <secret-name> --from-env MY_ENV_VAR
```

### Delete Secret
```powershell
docker mcp secret delete <secret-name>
```

## Common Use Cases

### Legal Research Workflow
```
Servers needed:
✅ brave-search (web search)
✅ exa-search (semantic search)
✅ wikipedia (reference)
✅ google-cloud-storage (backup)
✅ clickup-prod (task tracking)
✅ filesystem (local files)

Prompt examples:
- "Search Brave for recent Supreme Court decisions on AI"
- "Find semantic articles about contract law using Exa"
- "Search Wikipedia for precedent on data privacy"
- "List my ClickUp tasks for legal research"
```

### Development Workflow
```
Servers needed:
❌ github-prod (need token)
✅ task-orchestrator-prod (no key)
✅ clickup-prod (have keys)
✅ docker-management (no key)
✅ filesystem (no key)

Prompt examples:
- "Create a new task in task orchestrator for feature X"
- "List my GitHub issues"
- "Show running Docker containers"
- "Search filesystem for .py files with 'mcp' in them"
```

### AI/ML Experimentation
```
Servers needed:
✅ huggingface-prod (have token)
✅ brave-search (have key)
✅ runpod-management (have keys)
✅ google-cloud-storage (have keys)

Prompt examples:
- "Search Hugging Face for Llama models"
- "Find datasets about legal documents"
- "Check my RunPod GPU instances"
- "Upload model checkpoint to GCS"
```

## Get More API Keys

### Free Tier Available
- **Tavily**: https://tavily.com (500 free searches/month)
- **GitHub**: https://github.com/settings/tokens (unlimited for public repos)
- **OpenAI**: https://platform.openai.com (free tier available)

### Paid Services
- **Anthropic**: https://console.anthropic.com
- **Perplexity**: https://www.perplexity.ai/api
- **Google Gemini**: https://ai.google.dev

## Troubleshooting

### Gateway Won't Start
```powershell
# Check Docker is running
docker ps

# Check for port conflicts
netstat -ano | findstr :3333

# View detailed logs
docker logs mcp-gateway

# Restart Docker Desktop
```

### VS Code Not Seeing Servers
```powershell
# Reconnect
docker mcp client connect vscode

# Verify connection
code --list-extensions | Select-String mcp

# Restart VS Code completely
```

### Secrets Not Working
```powershell
# List all secrets
docker mcp secret list

# Re-sync from credentials.env
pwsh C:\DevWorkspace\MCP_2\scripts\sync-secrets.ps1

# Manually set specific secret
docker mcp secret set <name>
```

## Resources

- **Setup Guide**: `C:\DevWorkspace\MCP_2\docs\SETUP_NEW_SERVERS_GUIDE.md`
- **Catalog How-To**: `C:\DevWorkspace\MCP_2\docs\catalog-howto.md`
- **Credentials Template**: `C:\DevWorkspace\credentials.env.template`
- **Docker MCP Docs**: https://docs.docker.com/mcp/
- **MCP Protocol**: https://modelcontextprotocol.io

---

**Quick Start**: `pwsh C:\DevWorkspace\MCP_2\scripts\setup-production-servers.ps1`
