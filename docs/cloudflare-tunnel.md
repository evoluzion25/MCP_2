# Cloudflare Tunnel with Docker MCP Gateway

This document explains how the Cloudflare Tunnel exposes the Docker MCP Gateway and ensures all MCP servers are accessible remotely.

## Overview

The Cloudflare Tunnel provides secure remote access to your local MCP Gateway without opening firewall ports. All MCP servers running through the gateway are automatically accessible through the tunnel.

**Key Points:**
- Tunnel connects to: `http://mcp-gateway:3333` (SSE transport)
- Public endpoint: `https://mcp.rg1.io`
- **ALL servers** are automatically exposed - no per-server configuration needed
- The tunnel routes traffic to the gateway, which then spawns server containers on-demand

## Current Configuration

### Tunnel Details
- **Tunnel ID**: `741d42fb-5a6a-47f6-9b67-47e95011f865`
- **Hostname**: `mcp.rg1.io`
- **Protocol**: QUIC (4 tunnel connections)
- **Target**: `http://mcp-gateway:3333`

### Configuration File
Location: `C:\Users\ryan\.cloudflared\docker-config.yml`

```yaml
tunnel: 741d42fb-5a6a-47f6-9b67-47e95011f865
credentials-file: /etc/cloudflared/741d42fb-5a6a-47f6-9b67-47e95011f865.json
ingress:
  - hostname: mcp.rg1.io
    service: http://mcp-gateway:3333
  - service: http_status:404
```

## How It Works

```
Remote Client
    ↓
https://mcp.rg1.io
    ↓
Cloudflare Tunnel (4 connections)
    ↓
mcp-gateway:3333 (SSE/HTTP)
    ↓
Docker Socket
    ↓
Ephemeral MCP Server Containers (spawned on-demand)
```

### Automatic Server Discovery

The gateway handles all server routing internally:

1. **Client connects** → `https://mcp.rg1.io/sse`
2. **Gateway receives request** → Reads catalogs (docker-mcp.yaml + rg-mcp.yaml)
3. **Server needed** → Gateway spawns ephemeral container
4. **Request processed** → Response sent back through tunnel
5. **Container exits** → Automatic cleanup

**Result**: Any server enabled in the gateway is automatically accessible through the tunnel. No tunnel reconfiguration needed when adding servers.

## Server Synchronization

### Keeping docker-compose.yml Up-to-Date

The `docker-compose.yml` file includes a `--servers` flag that must list all enabled servers. Use the sync script to keep it current:

```powershell
# Check what would change
pwsh .\scripts\sync-servers.ps1 -DryRun

# Sync servers from registry to docker-compose.yml
pwsh .\scripts\sync-servers.ps1

# Restart gateway to apply changes
docker compose restart mcp-gateway
```

### What Gets Synchronized

The script reads from `C:\Users\ryan\.docker\mcp\registry.yaml` and updates the `--servers` line in `docker-compose.yml` to include:

✅ **All enabled servers** from Docker Desktop MCP UI
✅ **Custom servers** (like clickup)
✅ **Newly added servers** from either catalog

### When to Run Sync

Run the sync script whenever you:
- Enable/disable servers in Docker Desktop
- Add custom servers to catalogs
- Clone the repo on a new machine
- Notice servers missing from gateway logs

## Monitoring

### Check Tunnel Status
```powershell
# View tunnel logs
docker logs mcp-cloudflare-tunnel --tail 50

# Should see 4 "Registered tunnel connection" messages
```

### Check Gateway Exposure
```powershell
# Test from external machine
curl https://mcp.rg1.io

# View gateway logs
docker logs mcp-gateway --tail 50
```

### Verify Server List
```powershell
# List enabled servers
docker mcp server ls

# View gateway server count
docker logs mcp-gateway | Select-String "tools listed"
```

## Security Considerations

1. **Cloudflare Access**: Consider adding Access policies to restrict who can connect
2. **API Keys**: All secrets are passed through environment variables, never in tunnel config
3. **Rate Limiting**: Cloudflare provides DDoS protection automatically
4. **mTLS**: Can be enabled in tunnel config for client certificate authentication

## Troubleshooting

### Tunnel Not Connected
```powershell
# Check tunnel container
docker ps --filter "name=cloudflare"

# Restart tunnel
docker compose restart cloudflare-tunnel
```

### Servers Not Accessible Through Tunnel
1. Verify gateway is running: `docker ps --filter "name=mcp-gateway"`
2. Check gateway has server enabled: `docker mcp server ls`
3. Run sync script: `pwsh .\scripts\sync-servers.ps1`
4. Restart gateway: `docker compose restart mcp-gateway`

### New Server Not Showing
The tunnel doesn't need updates, but the gateway might:
```powershell
# Sync servers
pwsh .\scripts\sync-servers.ps1

# Restart gateway to load new server
docker compose restart mcp-gateway

# Verify
docker logs mcp-gateway | Select-String "tools listed"
```

## Adding New Servers (Automated)

When you add a new server:

1. **Enable in Docker Desktop** → MCP → Enable the server
2. **Run sync script** → `pwsh .\scripts\sync-servers.ps1`
3. **Restart gateway** → `docker compose restart mcp-gateway`
4. **Verify** → `docker logs mcp-gateway --tail 20`

The tunnel automatically routes requests to the updated gateway - no tunnel changes needed!

## Reference

- Cloudflare Tunnel Docs: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/
- Docker MCP Gateway: https://github.com/docker/mcp-gateway
- MCP Protocol: https://modelcontextprotocol.io/
