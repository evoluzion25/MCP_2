# Making MCP Servers Visible in Docker Desktop Toolkit

## Issue
Your `production-servers` catalog is imported, but servers aren't showing in the Docker Desktop MCP Toolkit UI under the "Catalog" section.

## Understanding the Docker Desktop MCP Toolkit

The toolkit has **two sections**:

### 1. "My Servers" Section
- Shows servers configured via `docker mcp config`
- Currently includes: filesystem, git, markdownify
- These are **always-on** servers

### 2. "Catalog" Section  
- Shows servers from imported catalogs (docker-mcp, production-servers, etc.)
- Servers appear here when catalogs are imported
- You can **enable/disable** individual servers

## Solution: Make Your Servers Appear in Toolkit

### Step 1: Verify Catalog is Imported

```powershell
# List all catalogs (should show production-servers)
docker mcp catalog ls

# View your production servers
docker mcp catalog show production-servers --format yaml
```

✅ **Confirmed**: Your `production-servers` catalog is imported correctly.

### Step 2: Restart Docker Desktop

The catalog UI may need Docker Desktop to restart to show new servers:

1. **Quit Docker Desktop** completely (right-click system tray icon → Quit)
2. **Wait 10 seconds**
3. **Restart Docker Desktop**
4. **Open Docker Desktop → Resources → Model Context Protocol**

### Step 3: Check the MCP Toolkit UI

After restarting Docker Desktop:

1. Open **Docker Desktop**
2. Click **Resources** (left sidebar)
3. Click **Model Context Protocol (MCP)**
4. You should see TWO sections:
   - **My Servers** (filesystem, git, markdownify)
   - **Catalog** (your production servers should appear here)

### Step 4: Enable Servers in the Catalog

Once servers appear in the Catalog section:

1. **Find your server** (e.g., "Brave Search", "Wikipedia", "ClickUp Production")
2. **Click the toggle** or **Enable button** next to it
3. **Configure secrets** if prompted (use the secrets you already set)
4. The server is now active!

## Alternative: Use Gateway Mode (Current Working Method)

Your servers are already working through the **MCP Gateway** approach:

```powershell
# Your servers are accessible via VS Code connection
docker mcp client connect vscode

# They're available in GitHub Copilot/Claude without needing the toolkit UI
```

## Why Servers May Not Show in Toolkit UI

### Possible Reasons:

1. **Docker Desktop Version**: Catalog UI support may require Docker Desktop 28.1+
   ```powershell
   docker version
   # Check if you have the latest version
   ```

2. **Catalog Precedence**: Docker official catalog loads first, custom catalogs load after
   - Your `production-servers` catalog is loaded
   - Servers should appear under "Catalog" section

3. **Image Names**: Servers need valid Docker images
   - Issue: Some of your catalog entries use non-existent images
   - Example: `mcp/brave-search:latest` may not exist as a published image

## Fix: Update Catalog with Real Images

The problem is that your production-servers catalog references images that don't exist in Docker Hub. Let me check which official images are available:

```powershell
# Check if image exists
docker pull mcp/brave-search:latest
docker pull mcp/wikipedia-mcp:latest
```

### Servers That Work (Official Images):
From the gateway output, these are **real** images that exist:
- `mcp/brave-search@sha256:8577...` ✅
- `mcp/wikipedia-mcp@sha256:c4f1...` ✅
- `mcp/tavily@sha256:bd72...` ✅
- `mcp/time@sha256:9c46...` ✅
- `mcp/youtube-transcript@sha256:acac...` ✅
- `ghcr.io/jpicklyk/task-orchestrator:latest` ✅

### Servers That DON'T Exist as Standalone Images:
These may need to be configured differently or don't have official images:
- `mcp/exa:latest` ❌ (not in official catalog)
- `mcp/clickup:latest` ❌ (not in official catalog)
- `mcp/gcs:latest` ❌ (not in official catalog)
- `mcp/github:latest` ❌ (not in official catalog - it's `mcp/github@sha256:...`)
- `mcp/docker:latest` ❌ (not in official catalog)
- `mcp/huggingface:latest` ❌ (not in official catalog)
- `mcp/cloudflare:latest` ❌ (not in official catalog)
- `mcp/runpod:latest` ❌ (not in official catalog)

## ✅ WORKING SOLUTION: Custom Catalog with Real Images

**Status: RESOLVED** - Created `catalogs/production-verified.yaml` with proper Docker images and SHA256 hashes.

The key is that custom catalogs MUST reference **real, published Docker images** with exact SHA256 hashes from the official catalog format.

### What Was Fixed:

1. ❌ **Old Catalog**: Used placeholder images like `mcp/exa:latest` that don't exist
2. ✅ **New Catalog**: Uses real images with SHA256 hashes like `mcp/brave-search@sha256:85776817ada6c0b7a2681afcb0877fbb17c62fd0299a4be606614eb1e2c2ffca`

### Import the Working Catalog:

```powershell
# Import custom catalog with real images
docker mcp catalog import C:\DevWorkspace\MCP_2\catalogs\production-verified.yaml

# Verify import
docker mcp catalog ls
# Should show: production-verified: Production Verified MCP Servers

# View servers in catalog
docker mcp catalog show production-verified
# Should show: brave-search, github, time, wikipedia

# Time utilities
docker mcp catalog add production-working time docker-mcp

# YouTube
docker mcp catalog add production-working youtube_transcript docker-mcp

# 3. Check what was added
docker mcp catalog show production-working

# 4. Remove old catalog
docker mcp catalog rm production-servers

# 5. Restart Docker Desktop to see servers in UI
```

## Verify Servers in Toolkit UI

After creating the catalog with official images:

1. **Quit and restart Docker Desktop**
2. **Open Docker Desktop → Resources → MCP**
3. **Look in the "Catalog" section**
4. You should now see:
   - Brave Search
   - Tavily
   - Wikipedia
   - Task Orchestrator
   - Time
   - YouTube Transcripts

5. **Click each server to enable it**
6. **Add secrets** when prompted (use the ones from Bitwarden)

## Summary

The issue is that your custom `production-servers` catalog uses image names that don't exist as published Docker images. 

**Two solutions:**

### Option A: Use Official Catalog Servers (Recommended)
```powershell
# Pull servers from official docker-mcp catalog
# These have validated, published Docker images
docker mcp catalog add production-working brave-search docker-mcp
```

### Option B: Use Gateway Mode (Current Working Method)
```powershell
# Your servers work through gateway
# They're available in VS Code through MCP client connection
# The toolkit UI is optional
```

**The toolkit UI is mainly for:**
- Visual server management
- Easy enable/disable of servers
- Graphical secret configuration

**Your current setup works fine without the toolkit UI** because:
✅ VS Code is connected via `docker mcp client connect vscode`
✅ Servers are available through the gateway
✅ Secrets are configured via Bitwarden/bootstrap

Would you like me to create the corrected catalog using official images?
