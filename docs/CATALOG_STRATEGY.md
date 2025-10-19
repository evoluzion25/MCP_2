# MCP Catalog Strategy

**Date**: October 18, 2025  
**Status**: ✅ Two-catalog system implemented

---

## 📋 Overview

The MCP_2 repository uses a **two-catalog strategy** for managing MCP servers:

1. **`docker-mcp`** - Official Docker catalog (read-only, 100+ servers)
2. **`rg-mcp`** - Custom RG catalog (editable, for servers not in official catalog)

---

## 🎯 Catalog Structure

### Official Docker Catalog (`docker-mcp`)

**Source**: Managed by Docker  
**Access**: Read-only  
**Servers**: 100+ official MCP servers  
**Update**: `docker mcp catalog update`

**Example Servers**:
- brave-search
- exa
- fetch
- git
- github
- memory
- playwright
- puppeteer
- sequentialthinking
- postgres
- redis
- mongodb
- And 90+ more...

### Custom RG Catalog (`rg-mcp`)

**Location**: `C:\DevWorkspace\MCP_2\catalogs\rg-mcp-catalog.yaml`  
**Access**: Fully editable  
**Purpose**: Servers not available in official catalog  
**Management**: Via Docker MCP CLI

**Current Servers**:
- **clickup** - Task management, time tracking, documents (13 tools)

---

## 🔧 How It Works

### ⚠️ CRITICAL: Catalog Directory Must Be Mounted

The gateway container MUST have access to `~/.docker/mcp/catalogs/` to read catalog files.

**In docker-compose.yml:**
```yaml
services:
  mcp-gateway:
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ${USERPROFILE}/.docker/mcp:/root/.docker/mcp:ro  # ← REQUIRED!
```

**Without this mount:**
- Gateway can't read catalog files
- All servers show "MCP server not found"
- 0 tools listed
- Gateway appears broken

**With this mount:**
- Gateway reads all catalogs successfully
- Servers spawn on-demand
- Tools listed correctly

### Catalog Precedence

When the gateway starts, catalogs are loaded in this order:

```
1. docker-mcp (Official) - Always loaded first
2. rg-mcp (Custom) - Loaded second
3. CLI-specified catalogs (via --catalog flag) - Highest precedence
```

If multiple catalogs define the same server name, the **last-loaded catalog wins**.

### Server Resolution

```yaml
# docker-compose.yml
--servers=brave,exa,fetch,git,memory,playwright,puppeteer,sequentialthinking,clickup
          ↑                                                                        ↑
    From docker-mcp catalog                                              From rg-mcp catalog
```

The gateway automatically resolves servers from all available catalogs.

---

## 📝 Managing the Custom Catalog

### View Catalogs

```powershell
# List all catalogs
docker mcp catalog ls

# Show servers in custom catalog
docker mcp catalog show rg-mcp

# Show servers in official catalog
docker mcp catalog show docker-mcp
```

### Add Servers to Custom Catalog

**Step 1**: Create server definition YAML file:

```yaml
# catalogs/my-new-server.yaml
name: my-catalog
displayName: My Catalog

registry:
  my-server:
    description: "What this server does"
    title: "Server Display Name"
    type: "server"
    image: "namespace/image:tag"
    tools:
      - name: "tool_name"
        description: "What the tool does"
    secrets:
      - name: "my-server.api_key"
        env: "API_KEY"
        example: "your-key-here"
```

**Step 2**: Add to your catalog:

```powershell
docker mcp catalog add rg-mcp my-server .\catalogs\my-new-server.yaml
```

**Step 3**: Verify:

```powershell
docker mcp catalog show rg-mcp
```

**Step 4**: Add to gateway in docker-compose.yml:

```yaml
--servers=brave,exa,fetch,git,memory,playwright,puppeteer,sequentialthinking,clickup,my-server
```

**Step 5**: Restart gateway:

```powershell
docker compose restart mcp-gateway
```

### Export Catalog for Backup

```powershell
# Export to file
docker mcp catalog export rg-mcp .\catalogs\rg-mcp-backup.yaml

# Commit to git for version control
git add catalogs/rg-mcp-backup.yaml
git commit -m "Backup custom catalog"
```

### Import Catalog

```powershell
# Import from file
docker mcp catalog import .\catalogs\rg-mcp-catalog.yaml
```

---

## 🌐 Adding Servers from Community Registry

To add servers from the MCP Community Registry:

```powershell
# 1. Find server ID from https://registry.modelcontextprotocol.io/
# 2. Import directly to your catalog
docker mcp catalog import rg-mcp --mcp-registry https://registry.modelcontextprotocol.io/v0/servers/{server-id}

# 3. Verify
docker mcp catalog show rg-mcp
```

---

## 📦 Current Configuration

### Catalogs

```powershell
PS> docker mcp catalog ls
rg-mcp: RG Custom MCP Catalog
docker-mcp: Docker MCP Catalog
```

### Servers in Gateway

**From `docker-mcp`** (8 servers):
1. brave-search (6 tools)
2. exa (1 tool)
3. fetch (1 tool + 1 prompt)
4. git (12 tools)
5. memory (9 tools)
6. playwright (21 tools)
7. puppeteer (7 tools + 1 resource)
8. sequentialthinking (1 tool)

**From `rg-mcp`** (1 server):
9. clickup (13 tools)

**Total**: 9 servers, 71 tools

---

## 🔄 Workflow for Adding New Servers

### Option 1: Server Available in Official Catalog

```powershell
# 1. Check if it exists
docker mcp catalog show docker-mcp | Select-String "server-name"

# 2. Add to docker-compose.yml
--servers=existing,servers,new-server-name

# 3. Set up secrets if needed
docker mcp secret set server.api_key

# 4. Restart gateway
docker compose restart mcp-gateway
```

### Option 2: Server NOT in Official Catalog

```powershell
# 1. Create server definition YAML
# See example above

# 2. Add to rg-mcp catalog
docker mcp catalog add rg-mcp server-name .\catalogs\server-definition.yaml

# 3. Add to docker-compose.yml
--servers=existing,servers,server-name

# 4. Set up secrets if needed
docker mcp secret set server.api_key

# 5. Restart gateway
docker compose restart mcp-gateway

# 6. Export catalog for backup
docker mcp catalog export rg-mcp .\catalogs\rg-mcp-catalog.yaml

# 7. Commit to git
git add catalogs/rg-mcp-catalog.yaml docker-compose.yml
git commit -m "Add server-name to custom catalog"
```

---

## 🎯 Best Practices

### ✅ Do:
- Use official `docker-mcp` catalog whenever possible
- Add custom servers to `rg-mcp` catalog
- Export and commit `rg-mcp` catalog regularly
- Document custom servers with proper descriptions
- Include all required secrets in server definitions
- Test new servers before committing

### ❌ Don't:
- Try to modify `docker-mcp` catalog (it's read-only)
- Create multiple custom catalogs for individual servers
- Forget to export custom catalog after changes
- Commit secrets to git (use placeholders in examples)
- Add servers to gateway without testing first

---

## 📊 Comparison

| Aspect | docker-mcp | rg-mcp |
|--------|-----------|--------|
| **Management** | Docker | You |
| **Access** | Read-only | Read-write |
| **Servers** | 100+ | Custom |
| **Updates** | Automatic | Manual |
| **Export** | ❌ Cannot | ✅ Can |
| **Modify** | ❌ Cannot | ✅ Can |
| **Purpose** | Official servers | Custom additions |

---

## 🔐 Secret Management

Servers in both catalogs use Docker MCP secrets:

```powershell
# Set secrets
docker mcp secret set server.api_key

# List secrets
docker mcp secret ls

# Use in catalog definition
secrets:
  - name: "server.api_key"
    env: "API_KEY"
```

Secrets are synced from Bitwarden using:
```powershell
pwsh .\scripts\bootstrap-machine.ps1 -Source bitwarden
```

---

## 📚 Documentation Links

- **Official Catalog Docs**: https://github.com/docker/mcp-gateway/blob/main/docs/catalog.md
- **MCP Registry**: https://registry.modelcontextprotocol.io/
- **Docker MCP Gateway**: https://github.com/docker/mcp-gateway

---

## 🎉 Current Status

✅ **Two-catalog system implemented**  
✅ **ClickUp added to rg-mcp catalog**  
✅ **Gateway configured with 9 servers (71 tools)**  
✅ **Catalog strategy documented**  
✅ **Workflow established for adding future servers**  

**Ready to add more custom servers following this pattern!** 🚀
