# Proper MCP Architecture with Docker Compose ✅

**Date**: October 18, 2025  
**Status**: PRODUCTION READY  
**Architecture**: Docker-based (recommended by Docker MCP documentation)

---

## 🏗️ Architecture Overview

Following the [official Docker MCP Gateway documentation](https://github.com/docker/mcp-gateway/blob/main/docs/mcp-gateway.md), the **recommended architecture** uses Docker Compose to run both the gateway and tunnel as containers.

```
┌─────────────────────────────────────────────────────────────────┐
│                      Docker Compose Stack                        │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐   │
│  │  mcp-gateway (Container)                                │   │
│  │  - Image: docker/mcp-gateway:latest                    │   │
│  │  - Transport: SSE                                       │   │
│  │  - Port: 3333 (mapped to host)                         │   │
│  │  - Access to docker.sock for server management         │   │
│  └──────────────────┬─────────────────────────────────────┘   │
│                     │                                           │
│  ┌──────────────────┴─────────────────────────────────────┐   │
│  │  cloudflare-tunnel (Container)                          │   │
│  │  - Image: cloudflare/cloudflared:latest                │   │
│  │  - Routes: mcp.rg1.io → mcp-gateway:3333              │   │
│  │  - Network: mcp-network (bridge)                       │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                            ▲                    ▲
                            │                    │
                      Local Access         Internet Access
                            │                    │
                    ┌───────┴──────┐    ┌────────┴────────┐
                    │ Claude, VS   │    │    ChatGPT      │
                    │ Code, LM     │    │  (via tunnel)   │
                    │ Studio, etc. │    │                 │
                    └──────────────┘    └─────────────────┘
```

---

## ✅ Why This Architecture?

### From the Official Documentation:

> "Running MCP Servers in Docker Containers is robust and secure."
> 
> "The simplest way to run the MCP Gateway with Docker Compose is with this kind of compose file..."

### Benefits:

1. **✅ Docker-Native**: Gateway runs as a container (official `docker/mcp-gateway` image)
2. **✅ Proper Networking**: Containers communicate via Docker bridge network
3. **✅ Service Discovery**: Tunnel can reach gateway via service name (`mcp-gateway:3333`)
4. **✅ Auto-Restart**: Both services restart automatically
5. **✅ Single Command**: `docker compose up` starts everything
6. **✅ Portable**: Works anywhere Docker runs (not just Windows)
7. **✅ Isolated**: No Windows processes, no port conflicts

---

## 📁 Configuration Files

### 1. docker-compose.yml

**Location**: `C:\DevWorkspace\MCP_2\docker-compose.yml`

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
      - --catalog=docker-mcp.yaml
      - --catalog=rg-mcp.yaml
      - --servers=brave,exa,fetch,git,memory,playwright,puppeteer,sequentialthinking,clickup
      - --verbose
      - --block-secrets=false
    ports:
      - "3333:3333"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ${USERPROFILE}/.docker/mcp:/root/.docker/mcp:ro
    environment:
      - BRAVE_API_KEY=${BRAVE_API_KEY}
      - EXA_API_KEY=${EXA_API_KEY}
    networks:
      - mcp-network

  cloudflare-tunnel:
    image: cloudflare/cloudflared:latest
    container_name: mcp-cloudflare-tunnel
    restart: unless-stopped
    command: tunnel --config /etc/cloudflared/docker-config.yml run
    volumes:
      - ${USERPROFILE}/.cloudflared:/etc/cloudflared:ro
    depends_on:
      - mcp-gateway
    networks:
      - mcp-network

networks:
  mcp-network:
    driver: bridge
```

### 2. Cloudflare Tunnel Config

**Location**: `C:\Users\ryan\.cloudflared\docker-config.yml`

```yaml
tunnel: 741d42fb-5a6a-47f6-9b67-47e95011f865
credentials-file: /etc/cloudflared/741d42fb-5a6a-47f6-9b67-47e95011f865.json

ingress:
  - hostname: mcp.rg1.io
    service: http://mcp-gateway:3333  # Service name, not localhost!
  - service: http_status:404
```

**Key Change**: Uses Docker service name `mcp-gateway` instead of `localhost` or `host.docker.internal`.

---

## 🚀 Usage

### Start the Stack

```powershell
cd C:\DevWorkspace\MCP_2
docker compose up -d
```

**Output**:
```
✔ Container mcp-gateway Started
✔ Container mcp-cloudflare-tunnel Started
```

### Stop the Stack

```powershell
docker compose down
```

### View Logs

```powershell
# All services
docker compose logs -f

# Gateway only
docker compose logs -f mcp-gateway

# Tunnel only
docker compose logs -f cloudflare-tunnel

# Last 50 lines
docker compose logs --tail 50
```

### Check Status

```powershell
docker compose ps
```

### Restart Services

```powershell
# Restart all
docker compose restart

# Restart gateway only
docker compose restart mcp-gateway

# Restart tunnel only
docker compose restart cloudflare-tunnel
```

---

## 🔍 Verification

### 1. Check Containers Are Running

```powershell
docker compose ps
```

**Expected Output**:
```
NAME                    STATUS         PORTS
mcp-gateway             Up X minutes   0.0.0.0:3333->3333/tcp
mcp-cloudflare-tunnel   Up X minutes
```

### 2. Check Gateway Logs

```powershell
docker compose logs mcp-gateway --tail 20
```

**Should Show**:
```
> Start sse server on port 3333
> 58 tools listed in 1.977s
> Initialized in 2.788s
```

### 3. Check Tunnel Logs

```powershell
docker compose logs cloudflare-tunnel --tail 10
```

**Should Show**:
```
INF Registered tunnel connection (4 times)
```

**Should NOT Show**:
```
ERR Unable to reach the origin service
ERR connection refused
```

### 4. Test Local Access

```powershell
Test-NetConnection -ComputerName localhost -Port 3333
# TcpTestSucceeded : True ✅
```

### 5. Test From ChatGPT

Go to ChatGPT and refresh actions. Should successfully connect to `https://mcp.rg1.io/sse` without 502 errors.

---

## 🔄 Auto-Start on Boot

### Docker Compose Auto-Start

With `restart: unless-stopped`, the stack will:
- ✅ Start automatically when Docker Desktop starts
- ✅ Restart if containers crash
- ✅ Stay stopped if you manually stop them
- ✅ Survive system reboots

**No Windows startup scripts needed!**

### Ensure Docker Desktop Starts on Boot

1. Open Docker Desktop settings
2. Go to **General**
3. Enable **Start Docker Desktop when you log in**

That's it! Everything will start automatically.

---

## 📊 Comparison: Old vs New Architecture

| Aspect | ❌ Old (Windows Process) | ✅ New (Docker Compose) |
|--------|-------------------------|------------------------|
| **Gateway Process** | Windows PowerShell process | Docker container |
| **Networking** | localhost/host.docker.internal | Docker bridge network |
| **Port Access** | Host network issues | Clean service-to-service |
| **Auto-Start** | Manual Windows startup | Docker restart policy |
| **Portability** | Windows only | Works anywhere |
| **Management** | Multiple scripts | Single `docker compose` |
| **Logs** | File at `%LOCALAPPDATA%\Mcp\` | `docker compose logs` |
| **Isolation** | Shares Windows network | Isolated Docker network |
| **Recommended** | ❌ No | ✅ Yes (official docs) |

---

## 🔧 Configuration Options

### Add More Servers

Edit `docker-compose.yml`:

```yaml
command:
  - --transport=sse
  - --port=3333
  - --servers=brave,exa,fetch,git,memory,playwright,puppeteer,sequentialthinking,wikipedia,time
  - --verbose
```

Then restart:
```powershell
docker compose up -d
```

### Add Environment Variables (Secrets)

Edit `docker-compose.yml`:

```yaml
environment:
  - BRAVE_API_KEY=${BRAVE_API_KEY}
  - EXA_API_KEY=${EXA_API_KEY}
  - GITHUB_TOKEN=${GITHUB_TOKEN}
  - OPENAI_API_KEY=${OPENAI_API_KEY}
```

Create `.env` file in same directory:
```env
BRAVE_API_KEY=your_key_here
EXA_API_KEY=your_key_here
GITHUB_TOKEN=your_token_here
```

### Change Port

Edit `docker-compose.yml`:

```yaml
ports:
  - "8080:3333"  # Expose on port 8080 instead
```

Don't forget to update Cloudflare config and `.env` files if needed.

---

## 🐛 Troubleshooting

### Containers Won't Start

**Check logs**:
```powershell
docker compose logs
```

**Common issues**:
- Port 3333 already in use: Change port in docker-compose.yml
- Docker not running: Start Docker Desktop
- Cloudflared config missing: Check `~/.cloudflared/docker-config.yml`

### ChatGPT Gets 502 Error

1. **Check gateway is running**:
   ```powershell
   docker compose ps
   # Should show "Up"
   ```

2. **Check tunnel logs**:
   ```powershell
   docker compose logs cloudflare-tunnel --tail 20
   ```
   Look for "connection refused" errors.

3. **Restart the stack**:
   ```powershell
   docker compose restart
   ```

### Gateway Can't Start MCP Servers

**Check Docker socket access**:
```yaml
volumes:
  - /var/run/docker.sock:/var/run/docker.sock
```

This must be present for the gateway to manage MCP server containers.

### Secrets Not Working

Add secrets to `docker-compose.yml` environment section and create `.env` file with actual values.

---

## 📝 Management Scripts

### Start Script

Create `C:\DevWorkspace\MCP_2\scripts\start-compose.ps1`:

```powershell
cd C:\DevWorkspace\MCP_2
docker compose up -d
docker compose ps
```

### Stop Script

Create `C:\DevWorkspace\MCP_2\scripts\stop-compose.ps1`:

```powershell
cd C:\DevWorkspace\MCP_2
docker compose down
```

### Status Script

Create `C:\DevWorkspace\MCP_2\scripts\status-compose.ps1`:

```powershell
cd C:\DevWorkspace\MCP_2
docker compose ps
Write-Host "`nGateway Logs:" -ForegroundColor Yellow
docker compose logs mcp-gateway --tail 10
Write-Host "`nTunnel Logs:" -ForegroundColor Yellow
docker compose logs cloudflare-tunnel --tail 10
```

---

## 🎉 Result

**Production-ready architecture following official Docker MCP documentation:**

- ✅ **Gateway**: Running as Docker container
- ✅ **Tunnel**: Running as Docker container
- ✅ **Networking**: Proper Docker bridge network
- ✅ **Service Discovery**: Containers communicate via service names
- ✅ **Auto-Restart**: Both services auto-restart
- ✅ **Local Access**: Claude, VS Code, LM Studio → `localhost:3333`
- ✅ **Internet Access**: ChatGPT → `https://mcp.rg1.io/sse` → gateway
- ✅ **No Windows Processes**: Everything in Docker
- ✅ **Single Command**: `docker compose up -d`

**No more 502 errors, no more connection refused, clean and maintainable!** 🚀
