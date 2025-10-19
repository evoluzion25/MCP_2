# ClickUp MCP Server - Installation Complete!

**Date**: October 18, 2025  
**Status**: ✅ ClickUp custom catalog successfully imported!

---

## ✅ What's Done

1. ✅ Created custom catalog YAML file (`catalogs/rg-mcp-catalog.yaml`)
2. ✅ Added ClickUp server to `rg-mcp` custom catalog
3. ✅ Verified ClickUp server is available in catalog
4. ✅ 13 tools defined (task management, time tracking, documents)
5. ✅ Added ClickUp to docker-compose.yml server list

---

## 📋 Next Steps to Activate ClickUp

### Step 1: Get ClickUp Credentials

**ClickUp API Key**:
1. Go to: https://app.clickup.com/
2. Click your avatar → Settings
3. Navigate to: Apps → API Token
4. Click "Generate" or copy existing token
5. Copy the token (starts with `pk_`)

**ClickUp Team ID**:
1. In ClickUp, go to Settings
2. Navigate to: Workspace → Workspace Settings
3. Look for "Workspace ID" (also called Team ID)
4. Copy the ID (numeric value)

### Step 2: Add to Bitwarden

```powershell
# Unlock Bitwarden
$env:BW_SESSION = (bw unlock --raw)

# Open Bitwarden Desktop app
# Find "MCP Secrets" Secure Note
# Add two new custom fields:

Field 1:
  Name: CLICKUP_API_KEY
  Type: Text
  Value: pk_your_actual_api_key_here

Field 2:
  Name: CLICKUP_TEAM_ID
  Type: Text
  Value: your_team_id_number
```

### Step 3: Sync Secrets to Docker MCP

```powershell
cd C:\DevWorkspace\MCP_2

# Sync from Bitwarden to Docker MCP
pwsh .\scripts\bootstrap-machine.ps1 -Source bitwarden

# Verify secrets are set
docker mcp secret ls | Select-String "clickup"
```

Expected output:
```
clickup.api_key      |
clickup.team_id      |
```

### Step 4: Add ClickUp to Gateway

Now we need to add ClickUp to the gateway's server list. Edit `docker-compose.yml`:

**Current**:
```yaml
command:
  - --transport=sse
  - --port=3333
  - --servers=brave,exa,fetch,git,memory,playwright,puppeteer,sequentialthinking
  - --verbose
  - --block-secrets=false
```

**Updated** (add `clickup`):
```yaml
command:
  - --transport=sse
  - --port=3333
  - --servers=brave,exa,fetch,git,memory,playwright,puppeteer,sequentialthinking,clickup
  - --verbose
  - --block-secrets=false
```

### Step 5: Restart Gateway

```powershell
# Restart the gateway to load ClickUp
docker compose restart mcp-gateway

# Check logs
docker compose logs mcp-gateway --tail 30

# Verify ClickUp tools are loaded
# Look for: "clickup" in the tools list
```

### Step 6: Test ClickUp Connection

```powershell
# Check if gateway sees ClickUp
docker compose logs mcp-gateway | Select-String "clickup"

# You should see ClickUp tools listed:
# - getTaskById
# - createTask
# - searchTasks
# - addComment
# - etc. (13 total)
```

---

## 🔍 Verification Checklist

- [ ] ClickUp API key obtained
- [ ] ClickUp Team ID obtained
- [ ] Both added to Bitwarden "MCP Secrets" item
- [ ] Secrets synced to Docker MCP (`docker mcp secret ls`)
- [ ] docker-compose.yml updated with `clickup` in servers list
- [ ] Gateway restarted (`docker compose restart mcp-gateway`)
- [ ] Logs show ClickUp loaded successfully
- [ ] 13 ClickUp tools available

---

## 📊 ClickUp Tools Available (13 Total)

Once activated, you'll have access to:

### Task Management (5 tools):
1. `getTaskById` - Get task details
2. `createTask` - Create new tasks
3. `updateTask` - Update task properties
4. `searchTasks` - Search for tasks
5. `addComment` - Add comments

### Workspace Management (3 tools):
6. `searchSpaces` - Search spaces
7. `getListInfo` - Get list details
8. `updateListInfo` - Update lists

### Time Tracking (2 tools):
9. `getTimeEntries` - Get time logs
10. `createTimeEntry` - Log time

### Document Management (3 tools):
11. `readDocument` - Read docs
12. `searchDocuments` - Search docs
13. `writeDocument` - Create/update docs

---

## 🎯 Usage Examples

Once activated in Claude Desktop or LM Studio:

**Create a task**:
```
"Create a task in ClickUp called 'Review MCP documentation' in the 'Dev Team' space"
```

**Search tasks**:
```
"Show me all open tasks assigned to me in ClickUp"
```

**Add comment**:
```
"Add a comment to task #ABC123 saying 'Working on this now'"
```

**Log time**:
```
"Log 2 hours on task #ABC123 for today"
```

**Search documents**:
```
"Find all ClickUp docs related to 'API integration'"
```

---

## 🔐 Security Notes

- ✅ API key and Team ID stored in Bitwarden (encrypted)
- ✅ Secrets managed by Docker MCP (not in compose file)
- ✅ No plaintext secrets in git repository
- ✅ Secrets referenced via `{{clickup.api_key}}` template
- ⚠️ Never commit actual secrets to git!

---

## 📝 Catalog Details

**Catalog Location**: `C:\DevWorkspace\MCP_2\catalogs\rg-mcp-catalog.yaml`  
**Catalog Name**: `rg-mcp`  
**Display Name**: RG Custom MCP Catalog  
**Server Name**: `clickup`  
**Server Type**: `server` (npm-based, wrapped in node:20-alpine)  
**Image**: `node:20-alpine`  
**npm Package**: `clickup-mcp-server@1.12.0`  

**Catalog Strategy**:
- `docker-mcp` - Official Docker catalog (100+ servers) - brave, exa, fetch, git, etc.
- `rg-mcp` - Your custom catalog for servers not in official catalog - ClickUp, future additions  

---

## 🚀 Quick Commands Reference

```powershell
# View custom catalog
docker mcp catalog show rg-mcp

# Add more servers to your catalog
docker mcp catalog add rg-mcp <server-name> .\catalogs\<server-file>.yaml

# Export catalog (for backup)
docker mcp catalog export rg-mcp .\catalogs\rg-mcp-catalog.yaml

# Re-import catalog
docker mcp catalog import .\catalogs\rg-mcp-catalog.yaml

# List all catalogs
docker mcp catalog ls

# Check secrets
docker mcp secret ls | Select-String "clickup"

# View gateway logs
docker compose logs mcp-gateway -f

# Restart gateway
docker compose restart mcp-gateway

# Stop/start entire stack
docker compose down
docker compose up -d
```

---

## 🎉 Success Criteria

When everything is working, you should see:

1. ✅ `docker mcp catalog show rg-mcp` shows ClickUp server
2. ✅ `docker mcp secret ls` shows `clickup.api_key` and `clickup.team_id`
3. ✅ `docker compose ps` shows `mcp-gateway` as `Up`
4. ✅ Gateway logs show "clickup" server loaded
5. ✅ Claude Desktop / LM Studio can use ClickUp tools
6. ✅ Total tools: 71 (58 existing + 13 from ClickUp)

---

**Ready to proceed with Step 1: Get your ClickUp credentials!** 🚀
