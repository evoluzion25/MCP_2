# MCP Server Architecture: Local + Internet Access

**Date**: October 18, 2025  
**Status**: Active

---

## 🏗️ Architecture Overview

This setup provides **dual access** to MCP servers:
1. **Local access** - Claude Desktop, VS Code, and other local apps
2. **Internet access** - ChatGPT and external services via Cloudflare Tunnel

```
┌─────────────────────────────────────────────────────────────┐
│                    Docker Desktop MCP                        │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  MCP Gateway (localhost:3333)                        │  │
│  │  - filesystem, markdownify, git servers              │  │
│  │  - Official docker-mcp catalog (100+ servers)        │  │
│  └──────────────────────────────────────────────────────┘  │
│                           │                                  │
└───────────────────────────┼──────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ▼                   ▼                   ▼
┌─────────────┐   ┌──────────────────┐   ┌────────────────┐
│   Local     │   │  Cloudflare      │   │   ChatGPT      │
│   Apps      │   │  Tunnel          │   │   (Internet)   │
│             │   │  (Docker)        │   │                │
│ - Claude    │   │                  │   │                │
│ - VS Code   │   │  mcp.rg1.io      │   │  https://      │
│ - Cursor    │   │       ▼          │   │  mcp.rg1.io    │
│ - Other     │   │  localhost:3333  │   │                │
└─────────────┘   └──────────────────┘   └────────────────┘
```

---

## 🔌 Components

### 1. Docker MCP Gateway (Local)
**Container**: Docker Desktop manages internally  
**Port**: `localhost:3333`  
**Access**: Local network only  
**Purpose**: Serves MCP servers to local applications

**Configuration**:
```yaml
filesystem:
  paths:
    - C:\Users\ryan\Apps\GitHub
    - C:\DevWorkspace
markdownify:
  paths:
    - C:\
    - G:\
git:
  paths:
    - C:\Users\ryan\Apps\GitHub
```

**Clients**:
- Claude Desktop (via `docker mcp client connect claude-desktop`)
- VS Code (via `docker mcp client connect vscode`)
- Cursor, Continue, Zed, etc.

### 2. Cloudflare Tunnel (Docker Container)
**Container Name**: `mcp-cloudflare-tunnel`  
**Image**: `cloudflare/cloudflared:latest`  
**Tunnel ID**: `741d42fb-5a6a-47f6-9b67-47e95011f865`  
**Public URL**: `https://mcp.rg1.io`  
**Purpose**: Expose MCP gateway to internet for ChatGPT

**Configuration** (`~/.cloudflared/docker-config.yml`):
```yaml
tunnel: 741d42fb-5a6a-47f6-9b67-47e95011f865
credentials-file: /etc/cloudflared/741d42fb-5a6a-47f6-9b67-47e95011f865.json

ingress:
  - hostname: mcp.rg1.io
    service: http://host.docker.internal:3333
  - service: http_status:404
```

**Status**: Running with 4 active connections to Cloudflare edge

---

## 🚀 Usage

### Local Apps (Claude, VS Code, etc.)
Connect directly to MCP gateway on `localhost:3333`:

```powershell
# Connect Claude Desktop
docker mcp client connect claude-desktop

# Connect VS Code
docker mcp client connect vscode

# Disconnect (if needed)
docker mcp client disconnect claude-desktop
```

**Claude Desktop Config** (manual alternative):
```json
{
  "mcpServers": {
    "MCP_DOCKER": {
      "command": "docker",
      "args": ["mcp", "client", "connect", "claude-desktop", "--global"],
      "env": {}
    }
  }
}
```

### ChatGPT (Internet Access)
ChatGPT can access your MCP servers via the public URL:

**URL**: `https://mcp.rg1.io`  
**Protocol**: SSE (Server-Sent Events) over HTTPS  
**Security**: Cloudflare tunnel encryption + authentication

**How ChatGPT Connects**:
1. ChatGPT makes request to `https://mcp.rg1.io`
2. Cloudflare tunnel routes to `localhost:3333` (MCP gateway)
3. MCP gateway processes request and returns response
4. Response sent back through tunnel to ChatGPT

---

## 🛠️ Management

### Start Cloudflare Tunnel
The container starts automatically (restart policy: `unless-stopped`).

Manual start:
```powershell
docker start mcp-cloudflare-tunnel
```

### Stop Cloudflare Tunnel
Temporarily stop internet access (local access continues):
```powershell
docker stop mcp-cloudflare-tunnel
```

### Check Tunnel Status
```powershell
# Check if running
docker ps --filter "name=mcp-cloudflare-tunnel"

# View logs
docker logs mcp-cloudflare-tunnel --tail 50

# Should show: "Registered tunnel connection" messages
```

### Restart Tunnel
```powershell
docker restart mcp-cloudflare-tunnel
```

---

## 🔒 Security

### Cloudflare Tunnel Benefits
- ✅ **No open ports** - No inbound firewall rules needed
- ✅ **Encrypted** - All traffic encrypted via Cloudflare tunnel
- ✅ **DDoS protection** - Cloudflare's network protects against attacks
- ✅ **Access control** - Can add Cloudflare Access policies if needed

### Credentials
**Location**: `C:\Users\ryan\.cloudflared\`
- `config.yml` - Original Windows config (for reference)
- `docker-config.yml` - Docker container config ⭐
- `741d42fb-5a6a-47f6-9b67-47e95011f865.json` - Tunnel credentials
- `cert.pem` - Cloudflare origin certificate

**Keep these files secure!** They provide access to your tunnel.

---

## 🐛 Troubleshooting

### Tunnel Not Connecting
```powershell
# Check logs
docker logs mcp-cloudflare-tunnel --tail 50

# Should see: "Registered tunnel connection" (4 times)
# If errors about credentials, check volume mount
```

### ChatGPT Can't Access
1. **Check tunnel is running**:
   ```powershell
   docker ps --filter "name=mcp-cloudflare-tunnel"
   ```

2. **Check MCP gateway is accessible**:
   ```powershell
   curl http://localhost:3333
   # Should respond (not 404)
   ```

3. **Check Cloudflare DNS**:
   ```powershell
   nslookup mcp.rg1.io
   # Should resolve to Cloudflare IPs
   ```

### Local Apps Can't Connect
Local apps don't need the tunnel! They connect directly:
```powershell
# Check Docker MCP is running
docker mcp catalog ls

# Reconnect client
docker mcp client connect claude-desktop
```

---

## 📝 Key Differences

### Before Cleanup
- ❌ Node.js MCP servers running on Windows
- ❌ Cloudflared process running on Windows (PID file)
- ❌ Multiple startup programs
- ❌ Duplicated services
- ❌ Docker container with wrong config

### After Cleanup ✅
- ✅ Only Docker MCP (single source)
- ✅ Cloudflared as Docker container
- ✅ No Windows processes
- ✅ No startup programs
- ✅ Clean, unified architecture

---

## 🔄 Docker Container Auto-Restart

The tunnel container is configured with `--restart unless-stopped`:
- ✅ Starts automatically when Docker Desktop starts
- ✅ Restarts if it crashes
- ✅ Stays stopped if you manually stop it
- ✅ Survives reboots

**No need for Windows startup programs!**

---

## 📊 Verification

### Verify Complete Setup
```powershell
# 1. Docker MCP running
docker mcp catalog ls
# Output: docker-mcp: Docker MCP Catalog

# 2. Tunnel container running
docker ps --filter "name=mcp-cloudflare-tunnel"
# Output: Up X seconds

# 3. Tunnel connected
docker logs mcp-cloudflare-tunnel --tail 5
# Output: "Registered tunnel connection" messages

# 4. No Windows processes
Get-Process | Where-Object { $_.ProcessName -eq 'cloudflared' }
# Output: (empty)

# 5. No startup programs
Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
# Output: No MCP entries
```

---

## 🎯 Summary

| Access Type | Method | URL/Port | Use Case |
|-------------|--------|----------|----------|
| **Local** | Direct connection | `localhost:3333` | Claude, VS Code, Cursor |
| **Internet** | Cloudflare Tunnel | `https://mcp.rg1.io` | ChatGPT, external apps |

Both methods access the **same MCP gateway** running in Docker Desktop.

**Result**: Clean, unified architecture with dual access paths! 🎉
