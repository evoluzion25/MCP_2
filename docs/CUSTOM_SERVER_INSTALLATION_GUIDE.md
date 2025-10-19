# Adding Custom MCP Servers - Complete Guide

**Date**: October 18, 2025  
**Status**: ✅ TESTED & WORKING  
**Example**: ClickUp MCP Server successfully integrated

---

## 🎯 Overview

This guide shows how to add **custom MCP servers** (not in the official Docker catalog) to your MCP gateway.

**Key Learnings:**
- MCP servers are **ephemeral containers** spawned on-demand, not persistent
- Custom catalogs require **Docker images**, not npm packages
- Catalogs must be **mounted** in docker-compose.yml to be accessible
- Environment variable names must **match exactly** what the server expects

---

## 📋 Prerequisites

- Docker Desktop with MCP CLI installed
- Docker Compose stack running
- npm package details for the MCP server you want to add
- Understanding that you'll need to build a custom Docker image

---

## 🏗️ Architecture Understanding

### How MCP Servers Work

```
┌─────────────────────────────────────────────────────────────┐
│  mcp-gateway (PERSISTENT)                                   │
│  - Always running                                           │
│  - Reads catalogs at startup from ~/.docker/mcp/catalogs/  │
│  - Has docker.sock access to spawn containers              │
└────────────────┬────────────────────────────────────────────┘
                 │
                 │ Client makes request
                 ▼
┌─────────────────────────────────────────────────────────────┐
│  Gateway spawns EPHEMERAL MCP server container:            │
│                                                             │
│  docker run --rm -i --init \                               │
│    --security-opt no-new-privileges \                      │
│    --cpus 1 --memory 2Gb \                                 │
│    -l docker-mcp=true \                                     │
│    -l docker-mcp-name=clickup \                            │
│    --network mcp_2_mcp-network \                           │
│    -e CLICKUP_API_TOKEN \                                  │
│    -e CLICKUP_TEAM_ID \                                    │
│    mcp/clickup:1.12.0                                      │
│                                                             │
│  - Container starts                                        │
│  - Processes request                                       │
│  - Returns response                                        │
│  - Container exits & is removed (--rm flag)                │
└─────────────────────────────────────────────────────────────┘
```

**Key Points:**
- ❌ You will NOT see MCP server containers in `docker ps` (they're ephemeral)
- ✅ You WILL see them briefly during active requests
- ✅ Gateway must have access to `~/.docker/mcp/catalogs/` directory
- ✅ Images must be pre-built (can't install npm packages at runtime)

---

## 🚀 Step-by-Step Process

### Step 1: Create Docker Image for the MCP Server

MCP servers from npm need to be wrapped in a Docker image.

**Example: ClickUp MCP Server**

Create `dockerfiles/clickup/Dockerfile`:

```dockerfile
# Dockerfile for ClickUp MCP Server
FROM node:20-alpine

# Install the MCP server globally
RUN npm install -g clickup-mcp-server@1.12.0

# Set working directory
WORKDIR /app

# Run the MCP server
CMD ["npx", "clickup-mcp-server"]
```

**Build the image:**

```powershell
cd C:\DevWorkspace\MCP_2
docker build -t mcp/clickup:1.12.0 -f dockerfiles/clickup/Dockerfile .
```

**Verify the image:**

```powershell
docker images | Select-String "mcp/clickup"
# Should show: mcp/clickup   1.12.0   [IMAGE_ID]   [SIZE]
```

---

### Step 2: Determine Required Environment Variables

**CRITICAL**: Check the actual MCP server code to find exact variable names.

**Example Investigation:**
```powershell
# Pull the npm package to inspect
npm info clickup-mcp-server

# Or check the GitHub repo/README
# https://github.com/nsxdavid/clickup-mcp-server
```

**For ClickUp:**
- ✅ `CLICKUP_API_TOKEN` (not `CLICKUP_API_KEY`!)
- ✅ `CLICKUP_TEAM_ID`

**Common Mistake:**
```yaml
# ❌ WRONG - using generic naming
env: "CLICKUP_API_KEY"

# ✅ CORRECT - matches what server expects
env: "CLICKUP_API_TOKEN"
```

---

### Step 3: Create Custom Catalog YAML

Create `catalogs/rg-mcp-catalog.yaml`:

```yaml
version: 2  # ← REQUIRED! Matches official catalog format
name: rg-mcp
displayName: RG Custom MCP Catalog

registry:
  clickup:  # ← Server name used in --servers flag
    description: "Search, create, and retrieve tasks and documents, add comments, and track time through natural language commands."
    title: "ClickUp"
    type: "server"
    dateAdded: "2025-10-18T00:00:00Z"
    image: "mcp/clickup:1.12.0"  # ← Your custom Docker image
    
    # Tools provided by this server (for documentation)
    tools:
      - name: "getTaskById"
        description: "Retrieve specific task details by task ID"
      - name: "createTask"
        description: "Create new tasks in ClickUp"
      - name: "updateTask"
        description: "Update task properties"
      # ... list all tools (optional but helpful)
    
    # Required secrets - maps Docker MCP secret names to env vars
    secrets:
      - name: "clickup.api_key"  # ← Docker MCP secret name
        env: "CLICKUP_API_TOKEN"  # ← Actual env var the server expects!
        example: "your-clickup-api-token"
      - name: "clickup.team_id"
        env: "CLICKUP_TEAM_ID"
        example: "your-team-id"
    
    # Metadata (optional but recommended)
    metadata:
      category: "task-management"
      tags: ["clickup", "task-management", "productivity"]
      license: "ISC"
      owner: "nsxdavid"
    
    # Documentation links (optional)
    readme: "https://github.com/nsxdavid/clickup-mcp-server/blob/main/README.md"
    source: "https://github.com/nsxdavid/clickup-mcp-server"
```

**Key Fields Explained:**

| Field | Required | Purpose |
|-------|----------|---------|
| `version: 2` | ✅ YES | Catalog format version |
| `name` | ✅ YES | Catalog identifier |
| `registry.{server-name}` | ✅ YES | Server name (used in `--servers` flag) |
| `image` | ✅ YES | Docker image (tag or SHA256) |
| `secrets.name` | ✅ YES | Docker MCP secret name |
| `secrets.env` | ✅ YES | Environment variable name server expects |
| `tools` | ❌ NO | Documentation only (gateway discovers at runtime) |
| `metadata` | ❌ NO | Categorization and discovery |

---

### Step 4: Import Catalog

```powershell
# Import the catalog file
docker mcp catalog import C:\DevWorkspace\MCP_2\catalogs\rg-mcp-catalog.yaml

# Verify import
docker mcp catalog ls
# Should show: rg-mcp: RG Custom MCP Catalog

# Check server is in catalog
docker mcp catalog show rg-mcp
# Should show: clickup: Search, create, and retrieve tasks...
```

---

### Step 5: Update docker-compose.yml

**CRITICAL REQUIREMENTS:**

1. Mount the catalog directory
2. Specify catalogs to load
3. Add server name to --servers list

```yaml
version: '3.8'

services:
  mcp-gateway:
    image: docker/mcp-gateway:latest
    container_name: mcp-gateway
    restart: unless-stopped
    command:
      - --transport=sse
      - --port=3333
      - --catalog=docker-mcp.yaml        # ← Official catalog
      - --catalog=rg-mcp.yaml            # ← Your custom catalog
      - --servers=brave,exa,fetch,git,memory,playwright,puppeteer,sequentialthinking,clickup  # ← Add your server
      - --verbose
      - --block-secrets=false
    ports:
      - "3333:3333"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ${USERPROFILE}/.docker/mcp:/root/.docker/mcp:ro  # ← REQUIRED! Mount catalogs
    environment:
      - BRAVE_API_KEY=${BRAVE_API_KEY}
      - EXA_API_KEY=${EXA_API_KEY}
    networks:
      - mcp-network
```

**Why the mount is required:**
- Gateway runs inside a container
- Default catalogs are at `~/.docker/mcp/catalogs/` on the HOST
- Without mount, gateway can't access catalog files
- Error: "MCP server not found" for ALL servers

---

### Step 6: Configure Secrets (Optional for Testing)

You can test without secrets first (server will error but you'll see it trying to start).

**With Bitwarden (Recommended):**

```powershell
# Add secrets to Bitwarden "MCP Secrets" item:
# - Custom field: clickup.api_key = your_token
# - Custom field: clickup.team_id = your_team_id

# Bootstrap secrets
pwsh .\scripts\bootstrap-machine.ps1 -Source bitwarden

# Verify
docker mcp secret ls
```

**Without Bitwarden (Manual):**

```powershell
docker mcp secret set clickup.api_key
# Enter your ClickUp API token

docker mcp secret set clickup.team_id  
# Enter your ClickUp team ID
```

---

### Step 7: Restart Gateway

```powershell
cd C:\DevWorkspace\MCP_2
docker compose restart mcp-gateway
```

**Wait 5 seconds, then check logs:**

```powershell
docker logs mcp-gateway --tail 50 2>&1 | Select-String -Pattern "clickup|tools listed"
```

**Expected Output (SUCCESS):**

```
- Reading catalog from [docker-mcp.yaml rg-mcp.yaml]
- Reading secrets [brave.api_key exa.api_key clickup.api_key clickup.team_id]
- mcp/clickup:1.12.0
- Those servers are enabled: brave, exa, fetch, git, memory, playwright, puppeteer, sequentialthinking, clickup
- Running mcp/clickup:1.12.0 with [run --rm -i --init ...]
- clickup: ClickUp MCP server running on stdio
  > clickup: (42 tools) (12 resources) (15 resourceTemplates)
> 100 tools listed in 2.082s
```

**Expected Output (No Secrets - Still Working):**

```
- Running mcp/clickup:1.12.0 with [run --rm -i --init ...]
- clickup: Error: CLICKUP_API_TOKEN environment variable is required
  > Can't start clickup: failed to connect: calling "initialize": EOF
> 58 tools listed in 2.121s
```

This is OK! It shows the server is found and starting. Add secrets to make it functional.

---

## 🔍 Troubleshooting

### "MCP server not found" for ALL servers

**Symptom:**
```
MCP server not found: brave
MCP server not found: exa
...
> 0 tools listed in 9.454µs
```

**Cause:** Catalog directory not mounted

**Fix:**
```yaml
# Add to docker-compose.yml volumes:
- ${USERPROFILE}/.docker/mcp:/root/.docker/mcp:ro
```

---

### "MCP server not found" only for your custom server

**Symptom:**
```
> clickup: (0 tools)
> Can't start clickup: MCP server not found
```

**Causes & Fixes:**

1. **Missing `version: 2` in catalog:**
   ```yaml
   version: 2  # ← Add this at top
   name: rg-mcp
   ```

2. **Catalog not imported:**
   ```powershell
   docker mcp catalog import C:\DevWorkspace\MCP_2\catalogs\rg-mcp-catalog.yaml
   ```

3. **Catalog not specified in docker-compose.yml:**
   ```yaml
   command:
     - --catalog=docker-mcp.yaml
     - --catalog=rg-mcp.yaml  # ← Add this
   ```

4. **Server not in --servers list:**
   ```yaml
   - --servers=brave,exa,fetch,git,memory,playwright,puppeteer,sequentialthinking,clickup  # ← Add server name
   ```

---

### Server starts but errors immediately

**Symptom:**
```
- clickup: Error: CLICKUP_API_TOKEN environment variable is required
```

**Causes:**

1. **Wrong environment variable name in catalog:**
   ```yaml
   # Check actual server code for exact variable name
   secrets:
     - name: "clickup.api_key"
       env: "CLICKUP_API_TOKEN"  # ← Must match what server expects!
   ```

2. **Secret not set:**
   ```powershell
   docker mcp secret set clickup.api_key
   docker mcp secret set clickup.team_id
   ```

3. **Secret name mismatch:**
   ```yaml
   # In catalog:
   secrets:
     - name: "clickup.api_key"  # ← This name
   
   # Must match Docker MCP secret:
   docker mcp secret set clickup.api_key  # ← This command
   ```

---

### Can't see MCP server containers running

**This is NORMAL!**

MCP servers are **ephemeral** - they start on-demand and exit after serving requests.

**To see them in action:**

1. Make a request from a client (Claude Desktop, ChatGPT, etc.)
2. Immediately run:
   ```powershell
   docker ps --filter "label=docker-mcp=true"
   ```
3. You might catch them for a few seconds!

**What you WILL see:**
```powershell
docker ps
# mcp-gateway             (always running)
# mcp-cloudflare-tunnel   (always running)
```

**What you WON'T see (usually):**
```powershell
# Individual MCP server containers (they're ephemeral)
```

---

## 📊 Verification Checklist

### ✅ Gateway Startup

```powershell
docker logs mcp-gateway --tail 50
```

**Should show:**
- ✅ `Reading catalog from [docker-mcp.yaml rg-mcp.yaml]`
- ✅ `Reading secrets [... clickup.api_key clickup.team_id]`
- ✅ `mcp/clickup:1.12.0`
- ✅ `Those servers are enabled: ... clickup`
- ✅ `Running mcp/clickup:1.12.0 with [run --rm -i --init ...]`
- ✅ `clickup: ClickUp MCP server running on stdio`
- ✅ `> clickup: (42 tools)`
- ✅ `> 100 tools listed` (or higher)

### ✅ Catalog Status

```powershell
# List catalogs
docker mcp catalog ls
# Should show: rg-mcp: RG Custom MCP Catalog

# Show custom catalog
docker mcp catalog show rg-mcp
# Should show: clickup: [description]
```

### ✅ Secrets Configured

```powershell
docker mcp secret ls | Select-String "clickup"
# Should show:
# clickup.api_key
# clickup.team_id
```

### ✅ Image Built

```powershell
docker images | Select-String "mcp/clickup"
# Should show: mcp/clickup   1.12.0   [ID]   [SIZE]
```

### ✅ Gateway Container Running

```powershell
docker compose ps
# Should show:
# mcp-gateway             Up X minutes   0.0.0.0:3333->3333/tcp
# mcp-cloudflare-tunnel   Up X minutes
```

---

## 🎯 Real-World Example: ClickUp Integration

**Result: Successfully added ClickUp with 42 tools**

### Files Created

1. **Docker Image**: `dockerfiles/clickup/Dockerfile`
2. **Catalog**: `catalogs/rg-mcp-catalog.yaml`
3. **Updated**: `docker-compose.yml` (added mount + catalog + server)

### Commands Run

```powershell
# Build image
docker build -t mcp/clickup:1.12.0 -f dockerfiles/clickup/Dockerfile .

# Import catalog
docker mcp catalog import C:\DevWorkspace\MCP_2\catalogs\rg-mcp-catalog.yaml

# Set secrets (optional for testing)
docker mcp secret set clickup.api_key
docker mcp secret set clickup.team_id

# Restart gateway
docker compose restart mcp-gateway

# Verify
docker logs mcp-gateway --tail 50 | Select-String "clickup|tools listed"
```

### Final Result

```
- Those servers are enabled: brave, exa, fetch, git, memory, playwright, puppeteer, sequentialthinking, clickup
  > clickup: (42 tools) (12 resources) (15 resourceTemplates)
> 100 tools listed in 2.082s
```

**Before:** 58 tools (8 servers)  
**After:** 100 tools (9 servers)  
**Added:** 42 tools from ClickUp ✅

---

## 📚 Key Takeaways

### ✅ Do:
1. Build a Docker image for npm-based MCP servers
2. Add `version: 2` to your catalog YAML
3. Mount `~/.docker/mcp:/root/.docker/mcp:ro` in docker-compose.yml
4. Verify exact environment variable names from server code
5. Import catalog after making changes
6. Add both `--catalog` and server name to docker-compose.yml

### ❌ Don't:
1. Try to install npm packages at runtime with `command:` in catalog
2. Expect to see MCP server containers in `docker ps` (they're ephemeral)
3. Use generic environment variable names without verifying
4. Forget to import catalog after editing YAML file
5. Skip mounting the catalog directory volume

### 🎓 Understanding:
- MCP servers are **spawned on-demand** by the gateway
- They run **briefly** and then exit (ephemeral containers)
- Gateway needs **Docker images**, not npm packages
- Catalogs must be **accessible** to gateway container
- Environment variable names must **exactly match** what server expects

---

## 🔗 References

- **ClickUp MCP Server**: https://github.com/nsxdavid/clickup-mcp-server
- **Docker MCP Gateway**: https://github.com/docker/mcp-gateway
- **Catalog Format**: https://github.com/docker/mcp-gateway/blob/main/docs/catalog.md
- **MCP Protocol**: https://modelcontextprotocol.io

---

**Last Updated**: October 18, 2025  
**Status**: ✅ Tested and working with ClickUp MCP Server
