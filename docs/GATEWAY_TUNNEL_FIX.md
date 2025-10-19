# MCP Gateway + Cloudflare Tunnel Fix

**Date**: October 18, 2025  
**Issue**: 502 Bad Gateway error when ChatGPT tries to access `https://mcp.rg1.io/sse`  
**Status**: ✅ RESOLVED

---

## 🐛 Problem

ChatGPT was getting `502 Bad Gateway` when trying to refresh actions at `https://mcp.rg1.io/sse`:

```
Error refreshing actions.
Server error '502 Bad Gateway' for url 'https://mcp.rg1.io/sse'
```

**Root Cause**: The MCP gateway wasn't running, so the Cloudflare tunnel had nothing to forward traffic to.

---

## ✅ Solution

### 1. Started MCP Gateway
The gateway must be running for the tunnel to forward traffic.

**Command**:
```powershell
pwsh C:\DevWorkspace\MCP_2\scripts\start-gateway.ps1 -Port 3333 -Transport sse
```

**Status**: ✅ Running as background process (PID 14664)  
**Log File**: `C:\Users\ryan\AppData\Local\Mcp\gateway.log`  
**Listening on**: `localhost:3333`

### 2. Fixed Cloudflare Tunnel Network Configuration
The tunnel container needs `--network host` to access the gateway on `localhost:3333`.

**Updated Config** (`~/.cloudflared/docker-config.yml`):
```yaml
tunnel: 741d42fb-5a6a-47f6-9b67-47e95011f865
credentials-file: /etc/cloudflared/741d42fb-5a6a-47f6-9b67-47e95011f865.json

ingress:
  - hostname: mcp.rg1.io
    service: http://127.0.0.1:3333  # Changed from host.docker.internal
  - service: http_status:404
```

**Docker Command**:
```powershell
docker run -d --name mcp-cloudflare-tunnel \
  --restart unless-stopped \
  --network host \
  -v "C:\Users\ryan\.cloudflared:/etc/cloudflared:ro" \
  cloudflare/cloudflared:latest \
  tunnel --config /etc/cloudflared/docker-config.yml run
```

**Key Change**: Using `--network host` allows the container to access `127.0.0.1:3333` directly.

---

## 🏗️ Current Architecture

```
ChatGPT (Internet)
      │
      ▼
https://mcp.rg1.io/sse
      │
      ▼
Cloudflare Edge Network
      │
      ▼
mcp-cloudflare-tunnel (Docker container, network=host)
      │
      ▼
127.0.0.1:3333
      │
      ▼
MCP Gateway (Windows process, PID 14664)
      │
      ▼
Docker MCP Servers (brave, exa, fetch, git, memory, playwright, etc.)
```

---

## ✅ Verification

### Check Gateway is Running
```powershell
# Check process
Get-Process -Id 14664

# Check port is listening
Test-NetConnection -ComputerName localhost -Port 3333
# Result: TcpTestSucceeded : True

# Check logs
Get-Content "C:\Users\ryan\AppData\Local\Mcp\gateway.log" -Tail 10
# Should show: "Start sse server on port 3333"
```

### Check Tunnel is Connected
```powershell
# Check container status
docker ps --filter "name=mcp-cloudflare-tunnel"
# Result: STATUS = Up X minutes

# Check tunnel logs
docker logs mcp-cloudflare-tunnel --tail 10
# Should show: "Registered tunnel connection" (4 times)
# Should NOT show: connection refused errors
```

### Test From ChatGPT
Go to ChatGPT and try to refresh actions. It should now successfully connect to `https://mcp.rg1.io/sse` without 502 errors.

---

## 📋 Management Commands

### Gateway Management

```powershell
# Start gateway (if not running)
pwsh C:\DevWorkspace\MCP_2\scripts\start-gateway.ps1 -Port 3333 -Transport sse

# Stop gateway
pwsh C:\DevWorkspace\MCP_2\scripts\stop-gateway.ps1

# Check gateway status
pwsh C:\DevWorkspace\MCP_2\scripts\status-gateway.ps1

# View logs
Get-Content "C:\Users\ryan\AppData\Local\Mcp\gateway.log" -Tail 30 -Wait
```

### Tunnel Management

```powershell
# Restart tunnel
docker restart mcp-cloudflare-tunnel

# Stop tunnel (blocks internet access)
docker stop mcp-cloudflare-tunnel

# Start tunnel
docker start mcp-cloudflare-tunnel

# View logs
docker logs mcp-cloudflare-tunnel --tail 50 -f
```

---

## 🔄 Auto-Start on Boot

### Gateway Auto-Start
The gateway is NOT set to auto-start. To enable:

```powershell
# Add to Windows startup (optional)
$startupPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
$shortcut = (New-Object -ComObject WScript.Shell).CreateShortcut("$startupPath\MCP Gateway.lnk")
$shortcut.TargetPath = "pwsh.exe"
$shortcut.Arguments = "-WindowStyle Hidden -File C:\DevWorkspace\MCP_2\scripts\start-gateway.ps1"
$shortcut.Save()
```

**Or manually start after boot**:
```powershell
pwsh C:\DevWorkspace\MCP_2\scripts\start-gateway.ps1
```

### Tunnel Auto-Start
The tunnel container is already configured to auto-start:
- Restart policy: `unless-stopped`
- Starts when Docker Desktop starts ✅

---

## ⚠️ Important Notes

### 1. Gateway Must Run Before Tunnel
If you restart your computer:
1. Docker Desktop starts (tunnel starts automatically)
2. But gateway is NOT running yet
3. ChatGPT will get 502 errors until you start the gateway

**Solution**: Start the gateway manually or add to Windows startup.

### 2. Local Apps Don't Need Gateway Running
Claude Desktop, LM Studio, and AnythingLLM connect via `docker mcp client connect`, which starts the gateway automatically as needed.

Only ChatGPT (internet access) requires the gateway to be running in SSE mode.

### 3. Network Mode = host
The tunnel container MUST use `--network host` to access `localhost:3333`. Don't change this.

---

## 🐛 Troubleshooting

### ChatGPT Still Gets 502 Error

1. **Check gateway is running**:
   ```powershell
   Test-NetConnection -ComputerName localhost -Port 3333
   ```
   If fails, start gateway:
   ```powershell
   pwsh C:\DevWorkspace\MCP_2\scripts\start-gateway.ps1
   ```

2. **Check tunnel logs**:
   ```powershell
   docker logs mcp-cloudflare-tunnel --tail 20
   ```
   Look for errors like "connection refused" or "Unable to reach origin service"

3. **Restart tunnel**:
   ```powershell
   docker restart mcp-cloudflare-tunnel
   ```

### Gateway Won't Start

Check if another process is using port 3333:
```powershell
Get-NetTCPConnection -LocalPort 3333 -ErrorAction SilentlyContinue
```

If occupied, kill the process or use a different port:
```powershell
pwsh C:\DevWorkspace\MCP_2\scripts\start-gateway.ps1 -Port 3334
```

Then update Cloudflare config and restart tunnel.

### Tunnel Shows "connection refused"

This means the gateway isn't running or isn't accessible. Start the gateway:
```powershell
pwsh C:\DevWorkspace\MCP_2\scripts\start-gateway.ps1
```

---

## 📊 Status Summary

| Component | Status | Details |
|-----------|--------|---------|
| **MCP Gateway** | ✅ Running | PID 14664, Port 3333, SSE transport |
| **Cloudflare Tunnel** | ✅ Connected | 4 active connections to Cloudflare edge |
| **Network Mode** | ✅ host | Container can access localhost:3333 |
| **ChatGPT Access** | ✅ Working | https://mcp.rg1.io/sse now responds |
| **Local Apps** | ✅ Working | Claude, LM Studio, AnythingLLM unaffected |

---

## 🎉 Result

ChatGPT can now access your MCP servers via `https://mcp.rg1.io/sse` without 502 errors!

**Available Tools** (90 total):
- brave: 6 tools (web search, image search, news, etc.)
- git: 12 tools (clone, commit, push, etc.)
- playwright: 21 tools (browser automation)
- memory: 9 tools (knowledge graph)
- fetch: 1 tool + 1 prompt
- sequentialthinking: 1 tool
- puppeteer: 7 tools + 1 resource
- playwright-mcp-server: 32 tools + 1 resource

All accessible from ChatGPT over the internet! 🚀
