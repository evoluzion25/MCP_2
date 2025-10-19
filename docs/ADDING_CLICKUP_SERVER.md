# Adding ClickUp MCP Server

**Date**: October 18, 2025  
**Status**: ClickUp is NOT in the official Docker MCP catalog  
**Solution**: Run as standalone npm package or create custom integration

---

## 🔍 ClickUp MCP Server Overview

**Package**: `clickup-mcp-server` (by nsxdavid)  
**Version**: 1.12.0 (latest)  
**NPM**: https://npm.im/clickup-mcp-server  
**GitHub**: https://github.com/nsxdavid/clickup-mcp-server

### Tools Available (13 total):
1. `getTaskById` - Retrieve specific task details
2. `addComment` - Add comments to tasks
3. `updateTask` - Update task properties
4. `createTask` - Create new tasks
5. `searchTasks` - Search for tasks
6. `searchSpaces` - Search ClickUp spaces
7. `getListInfo` - Get list information
8. `updateListInfo` - Update list properties
9. `getTimeEntries` - Retrieve time tracking entries
10. `createTimeEntry` - Log time on tasks
11. `readDocument` - Read ClickUp documents
12. `searchDocuments` - Search documents
13. `writeDocument` - Create/update documents

---

## ⚠️ Important Note

Based on our previous cleanup (October 18, 2025), we **removed all npm-based MCP servers** to standardize on Docker-only infrastructure. This was done to:
- ✅ Eliminate 203+ npm packages
- ✅ Remove Windows processes
- ✅ Standardize on Docker Compose architecture
- ✅ Simplify management

**Decision needed**: Do you want to:
1. **Keep Docker-only** (wait for official Docker image)
2. **Add exception for ClickUp** (install npm package)
3. **Create custom Docker image** (wrap npm package in container)

---

## 📋 Option 1: Docker Compose Service (Recommended)

Add ClickUp as a containerized npm service in `docker-compose.yml`:

```yaml
services:
  # ... existing mcp-gateway and cloudflare-tunnel ...

  clickup-mcp:
    image: node:20-alpine
    container_name: clickup-mcp
    restart: unless-stopped
    working_dir: /app
    command: >
      sh -c "npm install -g clickup-mcp-server@1.12.0 && 
      exec npx clickup-mcp-server"
    environment:
      - CLICKUP_API_KEY=${CLICKUP_API_KEY}
      - CLICKUP_TEAM_ID=${CLICKUP_TEAM_ID}
    networks:
      - mcp-network
    ports:
      - "3334:3334"  # If it exposes a port
```

### Get Required Credentials:

1. **ClickUp API Key**:
   ```
   Go to: ClickUp Settings > Apps > API Token
   Generate Personal API Token
   ```

2. **ClickUp Team ID**:
   ```
   Go to: ClickUp Settings > Workspace Settings
   Look for Workspace ID (also called Team ID)
   ```

3. **Add to Bitwarden**:
   ```powershell
   # Unlock Bitwarden
   $env:BW_SESSION = (bw unlock --raw)
   
   # Open Bitwarden Desktop app
   # Find "MCP Secrets" Secure Note
   # Add custom fields:
   #   - Name: CLICKUP_API_KEY
   #     Value: your-clickup-api-token
   #   - Name: CLICKUP_TEAM_ID
   #     Value: your-team-id
   ```

4. **Update manifest.yaml**:
   ```yaml
   # Already exists in C:\DevWorkspace\MCP_2\secrets\manifest.yaml:
   CLICKUP_API_KEY:
     mcp: clickup.api_key
   CLICKUP_TEAM_ID:
     mcp: clickup.team_id
   ```

5. **Sync to Docker MCP**:
   ```powershell
   pwsh .\scripts\bootstrap-machine.ps1 -Source bitwarden
   docker mcp secret ls | Select-String "clickup"
   ```

6. **Create .env file** (for Docker Compose):
   ```powershell
   # C:\DevWorkspace\MCP_2\.env
   CLICKUP_API_KEY=your-api-key-here
   CLICKUP_TEAM_ID=your-team-id-here
   BRAVE_API_KEY=your-brave-key
   EXA_API_KEY=your-exa-key
   ```

7. **Start the service**:
   ```powershell
   docker compose up -d clickup-mcp
   docker compose logs clickup-mcp
   ```

---

## 📋 Option 2: Standalone npm Package (Not Recommended)

If you must run outside Docker:

```powershell
# Install globally
npm install -g clickup-mcp-server@1.12.0

# Set environment variables
$env:CLICKUP_API_KEY = "your-api-key"
$env:CLICKUP_TEAM_ID = "your-team-id"

# Run server
npx clickup-mcp-server
```

### Add to Claude Desktop:

```json
{
  "mcpServers": {
    "clickup": {
      "command": "npx",
      "args": ["clickup-mcp-server"],
      "env": {
        "CLICKUP_API_KEY": "your-api-key",
        "CLICKUP_TEAM_ID": "your-team-id"
      }
    }
  }
}
```

**⚠️ Cons**:
- Breaks Docker-only architecture
- Adds npm package back to system
- Requires Windows process management
- Goes against our October 18 cleanup

---

## 📋 Option 3: Custom Docker Image (Advanced)

Create a Dockerfile to wrap the npm package:

```dockerfile
# C:\DevWorkspace\MCP_2\docker\clickup\Dockerfile
FROM node:20-alpine

WORKDIR /app

# Install ClickUp MCP server
RUN npm install -g clickup-mcp-server@1.12.0

# Expose port if needed
EXPOSE 3334

# Set entrypoint
ENTRYPOINT ["npx", "clickup-mcp-server"]
```

Build and push:
```powershell
cd C:\DevWorkspace\MCP_2\docker\clickup
docker build -t evoluzion25/clickup-mcp:1.12.0 .
docker push evoluzion25/clickup-mcp:1.12.0
```

Add to docker-compose.yml:
```yaml
  clickup-mcp:
    image: evoluzion25/clickup-mcp:1.12.0
    container_name: clickup-mcp
    restart: unless-stopped
    environment:
      - CLICKUP_API_KEY=${CLICKUP_API_KEY}
      - CLICKUP_TEAM_ID=${CLICKUP_TEAM_ID}
    networks:
      - mcp-network
```

---

## 🔐 Security Checklist

- [ ] ClickUp API key added to Bitwarden "MCP Secrets" item
- [ ] Team ID added to Bitwarden "MCP Secrets" item
- [ ] Secrets synced to Docker MCP: `docker mcp secret ls`
- [ ] .env file created (if using Docker Compose)
- [ ] .env file added to .gitignore (never commit secrets!)
- [ ] Service restarted: `docker compose restart clickup-mcp`

---

## 🎯 Recommended Approach

**I recommend Option 1 (Docker Compose Service)** because:
1. ✅ Keeps everything in Docker
2. ✅ Auto-restarts on boot
3. ✅ Centralized management
4. ✅ No Windows processes
5. ✅ Consistent with our architecture

**Next Steps**:
1. Get ClickUp API key and Team ID
2. Add to Bitwarden "MCP Secrets"
3. Sync to Docker MCP
4. Add service to docker-compose.yml
5. Create .env file with credentials
6. Start service: `docker compose up -d`

---

## 📊 Comparison

| Aspect | Docker Compose | npm Global | Custom Image |
|--------|---------------|------------|--------------|
| **Architecture** | ✅ Docker-only | ❌ Mixed | ✅ Docker-only |
| **Auto-restart** | ✅ Yes | ❌ No | ✅ Yes |
| **Secrets** | ✅ env vars | ⚠️ Manual | ✅ env vars |
| **Maintenance** | ✅ Easy | ⚠️ Manual | ⚠️ Build/push |
| **Startup** | ✅ Auto | ❌ Manual | ✅ Auto |
| **Isolation** | ✅ Container | ❌ Host | ✅ Container |

---

## 🚀 Quick Start (Recommended)

```powershell
# 1. Get credentials from ClickUp
# 2. Add to Bitwarden "MCP Secrets" item

# 3. Create .env file
cd C:\DevWorkspace\MCP_2
@"
CLICKUP_API_KEY=your-key-here
CLICKUP_TEAM_ID=your-team-id
BRAVE_API_KEY=from-bitwarden
EXA_API_KEY=from-bitwarden
"@ | Out-File .env -Encoding utf8

# 4. Add to docker-compose.yml (see Option 1 above)

# 5. Start service
docker compose up -d clickup-mcp

# 6. Verify
docker compose ps
docker compose logs clickup-mcp --tail 20
```

---

**Status**: Waiting for user decision on which option to implement.
