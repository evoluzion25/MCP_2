# Understanding Docker MCP Gateway Architecture

**Date**: October 18, 2025  
**Status**: CLARIFICATION

---

## 🔍 How MCP Servers Actually Work

### ❌ Common Misconception
MCP servers are **NOT** persistent containers running 24/7 like the gateway.

### ✅ Actual Behavior
MCP servers are **ephemeral, on-demand containers** that:

1. **Start** when a client makes a request
2. **Run** for the duration of the session/request
3. **Stop** when the request completes
4. Are **automatically cleaned up** (unless `--long-lived` flag is set)

---

## 🏗️ Architecture

```
┌──────────────────────────────────────────────────────────────┐
│  mcp-gateway (PERSISTENT CONTAINER)                          │
│  - Always running                                            │
│  - Listens on port 3333                                      │
│  - Has access to docker.sock                                 │
│  - Reads catalogs at startup                                 │
│  - Spawns MCP server containers on-demand                    │
└──────────────────────────────────────────────────────────────┘
                              │
                              │ Client Request
                              ▼
┌──────────────────────────────────────────────────────────────┐
│  Gateway spawns ephemeral MCP server container:              │
│                                                              │
│  docker run --rm -i --init \                                │
│    --security-opt no-new-privileges \                       │
│    --cpus 1 --memory 2Gb \                                  │
│    -l docker-mcp=true \                                      │
│    -l docker-mcp-name=brave \                               │
│    --network mcp_2_mcp-network \                            │
│    -e BRAVE_API_KEY \                                       │
│    mcp/brave-search@sha256:...                              │
│                                                              │
│  Container runs, processes request, returns response,        │
│  then exits and is automatically removed (--rm flag)         │
└──────────────────────────────────────────────────────────────┘
```

---

## 📋 What You See

### Running Containers (`docker ps`)

**ALWAYS visible**:
- `mcp-gateway` - The persistent gateway container
- `mcp-cloudflare-tunnel` - The persistent tunnel container

**ONLY visible during active requests**:
- MCP server containers (brief, seconds to minutes)
- Labels: `docker-mcp=true`, `docker-mcp-name=<server>`

### Example During Request

```powershell
PS> docker ps
NAME                    IMAGE                           STATUS
mcp-gateway             docker/mcp-gateway:latest       Up 10 minutes
mcp-cloudflare-tunnel   cloudflare/cloudflared:latest   Up 10 minutes
brave-xyz123            mcp/brave-search@sha256:...     Up 2 seconds  # ← Ephemeral!
```

A few seconds later:
```powershell
PS> docker ps
NAME                    IMAGE                           STATUS
mcp-gateway             docker/mcp-gateway:latest       Up 11 minutes
mcp-cloudflare-tunnel   cloudflare/cloudflared:latest   Up 11 minutes
# brave-xyz123 is gone - request completed!
```

---

## 🔧 Gateway Startup Behavior

### Normal Startup Logs

```
- Reading configuration...
- Reading catalog from [docker-mcp.yaml rg-mcp.yaml]
- Configuration read in 41.612µs
- Those servers are enabled: brave, exa, fetch, git, memory, playwright, puppeteer, sequentialthinking, clickup
- Listing MCP tools...
  - Running mcp/brave with [run --rm -i --init ...]
  - Running mcp/exa with [run --rm -i --init ...]
  ...
> 58 tools listed in 2.1s
> Start sse server on port 3333
```

### What "MCP server not found" Means

**During `- Listing MCP tools...` phase**:
- Gateway spawns each server briefly to query available tools
- If image needs pulling: may show "MCP server not found" temporarily
- Once pulled: server starts, lists tools, exits

**If you see** `> 0 tools listed`:
- NO servers were successfully queried
- Could mean:
  - Images not pulled
  - Catalog format incorrect
  - Docker sock issue
  - Network issue

**If you see** `> 58 tools listed`:
- Gateway successfully queried all servers ✅
- Servers are ready to use
- They will spawn on-demand when clients connect

---

## 🐛 Current Issue

```
- Those servers are enabled: brave, exa, fetch, git, memory, playwright, puppeteer, sequentialthinking, clickup
- Listing MCP tools...
  - MCP server not found: brave
  - MCP server not found: exa
  ...
> 0 tools listed in 9.454µs
```

**This is ABNORMAL** because:
1. All images are present locally (verified via `docker images`)
2. Gateway reads both catalogs successfully
3. Servers are enabled in the command
4. But gateway can't find/start them

**Possible causes**:
1. Catalog format mismatch between v1 and v2
2. Gateway expects SHA256 image hashes, not tags
3. Missing required fields in catalog YAML
4. Docker sock permission issue
5. Network configuration issue

---

## 🔍 Diagnosis Steps

### 1. Check if gateway can spawn containers

```powershell
# Try to manually spawn a server the way gateway does
docker run --rm -i --init \
  --security-opt no-new-privileges \
  --cpus 1 --memory 2Gb \
  -l docker-mcp=true \
  -l docker-mcp-name=brave \
  --network mcp_2_mcp-network \
  mcp/brave-search@sha256:85776817ada6c0b7a2681afcb0877fbbb17c62fd0299a4be606614eb1e2c2ffca
```

If this works, the issue is catalog format.

### 2. Check catalog compatibility

Official docker-mcp catalog uses:
```yaml
version: 2
name: docker-mcp
displayName: Docker MCP Catalog
registry:
  brave:
    image: mcp/brave-search@sha256:85776817ada6c0b7...
```

Our rg-mcp catalog uses:
```yaml
version: 2
name: rg-mcp
displayName: RG Custom MCP Catalog
registry:
  clickup:
    image: mcp/clickup:1.12.0  # ← Tag instead of SHA256?
```

### 3. Check gateway can see docker

```powershell
docker exec mcp-gateway docker ps
```

Should list running containers. If error, docker.sock mount issue.

---

## 📝 Documentation Sources

- **Official Gateway Docs**: https://github.com/docker/mcp-gateway/blob/main/docs/mcp-gateway.md
- **Catalog Format**: https://github.com/docker/mcp-gateway/blob/main/docs/catalog.md
- **MCP Protocol**: https://modelcontextprotocol.io

