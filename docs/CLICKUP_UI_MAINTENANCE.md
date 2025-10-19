# ClickUp in Docker Desktop UI - Maintenance Scripts

**Problem**: Docker Desktop periodically updates `docker-mcp.yaml`, removing custom entries like ClickUp.

**Solution**: Use these scripts to automatically re-add ClickUp after Docker updates the catalog.

---

## 📜 Scripts

### 1. `check-clickup-in-catalog.ps1`

**Purpose**: Check if ClickUp exists in docker-mcp.yaml

**Usage**:
```powershell
# Check if ClickUp exists
pwsh .\scripts\check-clickup-in-catalog.ps1

# Check and auto-fix if missing
pwsh .\scripts\check-clickup-in-catalog.ps1 -AutoFix
```

**Output**:
- ✅ Shows when ClickUp is present
- ❌ Warns when ClickUp is missing
- 📅 Shows when catalog was last modified

**Example Output**:
```
✅ ClickUp exists in docker-mcp.yaml
📅 Catalog last modified: 10/18/2025 22:07:57
```

### 2. `add-clickup-to-catalog.ps1`

**Purpose**: Add ClickUp to docker-mcp.yaml if it's missing

**Usage**:
```powershell
pwsh .\scripts\add-clickup-to-catalog.ps1
```

**What it does**:
1. ✅ Creates backup of docker-mcp.yaml
2. ✅ Checks if ClickUp already exists (skips if found)
3. ✅ Adds ClickUp entry in official catalog format
4. ✅ Verifies the addition was successful
5. ✅ Provides next steps

**Output**:
```
🔄 Adding ClickUp to docker-mcp.yaml...
📦 Creating backup...
✅ Backup created: C:\Users\ryan\.docker\mcp\catalogs\docker-mcp.yaml.backup
✅ ClickUp added to docker-mcp.yaml
✅ Verification successful - ClickUp is in the catalog

📋 Next steps:
  1. Restart Docker Desktop to see ClickUp in the UI
  2. Open Docker Desktop → Extensions → MCP
  3. ClickUp should now appear in the server list

⚠️  Note: Run this script again after Docker updates docker-mcp.yaml
```

---

## 🔄 Workflow

### Initial Setup (Already Done)

✅ ClickUp has been added to docker-mcp.yaml  
✅ Backup created  
✅ Scripts ready to use

### When Docker Updates the Catalog

Docker Desktop periodically updates `docker-mcp.yaml` from its official source, which will **remove** ClickUp.

**You'll know this happened when:**
- ClickUp disappears from Docker Desktop UI
- Gateway still works (uses rg-mcp.yaml)

**To fix:**

```powershell
# Option 1: Check first, then decide
pwsh .\scripts\check-clickup-in-catalog.ps1
# If missing, run:
pwsh .\scripts\add-clickup-to-catalog.ps1

# Option 2: Auto-fix (recommended)
pwsh .\scripts\check-clickup-in-catalog.ps1 -AutoFix
```

---

## 🤖 Automated Monitoring (Optional)

### Create a Scheduled Task

You can schedule the check script to run daily and auto-fix:

```powershell
# Create scheduled task to check daily
$action = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-File C:\DevWorkspace\MCP_2\scripts\check-clickup-in-catalog.ps1 -AutoFix"
$trigger = New-ScheduledTaskTrigger -Daily -At 9am
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERNAME" -LogonType Interactive
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

Register-ScheduledTask -TaskName "MCP - Check ClickUp in Catalog" -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description "Checks if ClickUp exists in docker-mcp.yaml and re-adds if missing"
```

**To remove the task later:**
```powershell
Unregister-ScheduledTask -TaskName "MCP - Check ClickUp in Catalog" -Confirm:$false
```

---

## 📁 Files Created

1. **`scripts/add-clickup-to-catalog.ps1`**
   - Adds ClickUp to docker-mcp.yaml
   - Creates backup before modifying
   - Verifies the addition

2. **`scripts/check-clickup-in-catalog.ps1`**
   - Checks if ClickUp exists
   - Shows last modified date
   - Can auto-fix with -AutoFix flag

3. **Backup file** (auto-created):
   - `C:\Users\ryan\.docker\mcp\catalogs\docker-mcp.yaml.backup`
   - Created each time add-clickup-to-catalog.ps1 runs

---

## 🔍 Troubleshooting

### ClickUp not showing in Docker Desktop UI

**Try:**
1. Run check script: `pwsh .\scripts\check-clickup-in-catalog.ps1`
2. If missing, run: `pwsh .\scripts\add-clickup-to-catalog.ps1`
3. **Restart Docker Desktop**
4. Open Docker Desktop → Extensions → MCP
5. ClickUp should appear in server list

### Script says "ClickUp exists" but not in UI

**Try:**
1. Restart Docker Desktop (may need to refresh cache)
2. Check Docker Desktop logs
3. Verify docker-mcp.yaml manually:
   ```powershell
   cat "$env:USERPROFILE\.docker\mcp\catalogs\docker-mcp.yaml" | Select-String "clickup" -Context 3
   ```

### Want to restore original catalog

**Use the backup:**
```powershell
Copy-Item "$env:USERPROFILE\.docker\mcp\catalogs\docker-mcp.yaml.backup" "$env:USERPROFILE\.docker\mcp\catalogs\docker-mcp.yaml" -Force
```

---

## ⚠️ Important Notes

### Gateway vs UI

- **Gateway** (what serves tools): Uses BOTH docker-mcp.yaml AND rg-mcp.yaml
  - ClickUp works even if removed from docker-mcp.yaml
  - Tools still available to Claude, ChatGPT, etc.

- **Docker Desktop UI**: Only shows servers from docker-mcp.yaml
  - Needs ClickUp in docker-mcp.yaml to display
  - This is why we use these scripts

### Why Two Catalogs?

1. **rg-mcp.yaml** (custom catalog)
   - Used by gateway ✅
   - NOT shown in Docker Desktop UI ❌
   - Never gets overwritten ✅
   - ClickUp is here permanently

2. **docker-mcp.yaml** (official catalog)
   - Used by gateway ✅
   - Shown in Docker Desktop UI ✅
   - Gets overwritten by Docker updates ❌
   - We add ClickUp here for UI visibility only

**Best of both worlds:**
- rg-mcp.yaml ensures ClickUp always works
- docker-mcp.yaml addition makes it visible in UI
- Scripts make re-adding easy after Docker updates

---

## 📊 Status Check Commands

```powershell
# Check if ClickUp in docker-mcp.yaml
pwsh .\scripts\check-clickup-in-catalog.ps1

# List all catalogs
docker mcp catalog ls

# Show rg-mcp catalog (permanent home for ClickUp)
docker mcp catalog show rg-mcp

# List all available servers
docker mcp server ls

# Check gateway logs for ClickUp
docker logs mcp-gateway --tail 50 | Select-String "clickup"
```

---

## 🎯 Summary

**Goal**: See ClickUp in Docker Desktop UI  
**Method**: Add to docker-mcp.yaml  
**Challenge**: Docker overwrites docker-mcp.yaml periodically  
**Solution**: Scripts to easily re-add ClickUp after updates  

**Current Status**: ✅ ClickUp added to docker-mcp.yaml  
**Maintenance**: Run check script after Docker Desktop updates  

---

**Last Updated**: October 18, 2025  
**Scripts Location**: `C:\DevWorkspace\MCP_2\scripts\`  
**Backup Location**: `C:\Users\ryan\.docker\mcp\catalogs\docker-mcp.yaml.backup`
