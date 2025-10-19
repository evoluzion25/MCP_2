# Adding Custom MCP Servers to Docker Desktop

This guide shows you how to add custom MCP servers that aren't in the official catalog.

## Prerequisites

- Docker Desktop 28+ with MCP support
- Docker CLI (`docker mcp` commands available)
- Custom server configuration (YAML format)

---

## Method 1: Import Custom Catalog (Recommended)

### Step 1: Create a Custom Catalog YAML File

Create a YAML file (e.g., `custom-catalog.yaml`) that defines your MCP servers:

```yaml
version: 2
name: my-custom-catalog
displayName: My Custom MCP Servers
registry:
  my-server:
    description: Description of what this server does
    title: My Server Title
    type: server
    dateAdded: "2025-10-18T00:00:00Z"
    image: mcp/server-name@sha256:abc123...  # Must be real image with SHA256
    ref: ""
    source: https://github.com/org/repo
    upstream: https://github.com/org/repo
    tools:
      - name: tool_1
      - name: tool_2
    secrets:
      - name: my.api_key
        env: MY_API_KEY
        example: YOUR_API_KEY_HERE
    env:
      - name: MCP_TRANSPORT
        value: stdio
    prompts: 0
    resources: {}
    metadata:
      category: utilities
      tags:
        - tag1
        - tag2
      license: MIT License
```

**IMPORTANT**: The `image` field MUST reference:
- A **real, published Docker image** (not placeholder like `mcp/server:latest`)
- Include the **full SHA256 hash** (e.g., `mcp/brave-search@sha256:85776817...`)
- You can get SHA256 hashes from the official catalog: `docker mcp catalog show docker-mcp --format yaml`

### Step 2: Import the Custom Catalog

```powershell
# Import your custom catalog
docker mcp catalog import C:\path\to\custom-catalog.yaml

# Verify it was imported
docker mcp catalog ls
# Should show your catalog name

# View servers in the catalog
docker mcp catalog show my-custom-catalog
```

### Step 3: Restart Docker Desktop

After importing the catalog, restart Docker Desktop to see servers in the UI:
1. Right-click Docker Desktop tray icon → **Quit Docker Desktop**
2. Reopen Docker Desktop
3. Navigate to **Resources → MCP → Catalog**
4. Your custom catalog servers should appear

---

## Method 2: Add Server to Existing Catalog

If you want to add a server to an existing catalog:

```powershell
# Syntax
docker mcp catalog add <catalog-name> <server-name> <catalog-file>

# Example: Add github server from a catalog file
docker mcp catalog add my-catalog github-server ./github-catalog.yaml

# Use --force to overwrite existing server
docker mcp catalog add my-catalog github-server ./github-catalog.yaml --force
```

**Note**: You **cannot** add individual servers from the official `docker-mcp` catalog using this method. The official catalog is managed by Docker and cannot be exported or modified.

---

## Method 3: Create Empty Catalog and Build It

```powershell
# 1. Create an empty catalog
docker mcp catalog create my-new-catalog

# 2. Add servers one at a time (requires catalog file for each)
docker mcp catalog add my-new-catalog server1 ./server1-definition.yaml
docker mcp catalog add my-new-catalog server2 ./server2-definition.yaml

# 3. Verify servers were added
docker mcp catalog show my-new-catalog
```

---

## Working Example: production-verified Catalog

See `catalogs/production-verified.yaml` for a complete working example with:
- ✅ Real Docker images with SHA256 hashes
- ✅ Proper server metadata and configuration
- ✅ Secrets and environment variable definitions
- ✅ Tools, prompts, and resources lists

### Servers Included:
- **brave-search**: Web search using Brave API
- **github**: GitHub repository management
- **time**: Time and timezone utilities
- **wikipedia**: Wikipedia article search and retrieval

### Import It:
```powershell
docker mcp catalog import C:\DevWorkspace\MCP_2\catalogs\production-verified.yaml
docker mcp catalog show production-verified
```

---

## Where Do Servers Appear?

After importing a catalog:
1. **Docker Desktop UI**: Resources → MCP → **Catalog** section
2. **Gateway**: Servers available when you start the gateway with `--enable-all-servers`
3. **VS Code**: Available when connected via `docker mcp client connect vscode`

---

## Troubleshooting

### Servers Don't Appear in UI

**Problem**: Custom catalog imported but servers don't show in Docker Desktop → Resources → MCP → Catalog

**Causes**:
1. Docker images don't exist or aren't accessible
2. SHA256 hashes are missing or incorrect
3. Docker Desktop needs restart
4. Catalog format is invalid

**Solutions**:
```powershell
# Verify catalog format
docker mcp catalog show my-catalog --format yaml

# Check if image exists (for testing)
docker pull mcp/server-name@sha256:abc123...

# Restart Docker Desktop
# Right-click tray icon → Quit Docker Desktop → Reopen

# View gateway logs
docker ps -a | Select-String mcp
docker logs <container-id>
```

### Can't Add from Official Catalog

**Error**: `catalog file 'docker-mcp' not found` when trying:
```powershell
docker mcp catalog add my-catalog brave-search docker-mcp
```

**Explanation**: The official `docker-mcp` catalog is managed by Docker and cannot be used as a source for individual server additions. You must:
1. Get the server definition from the official catalog YAML export
2. Copy it to your custom catalog file
3. Import your custom catalog

**Workaround**:
```powershell
# View official catalog to get server definitions
docker mcp catalog show docker-mcp --format yaml | Out-File official-catalog.yaml

# Copy the server definition you want from official-catalog.yaml
# Paste it into your custom-catalog.yaml
# Import your custom catalog
docker mcp catalog import custom-catalog.yaml
```

---

## Best Practices

1. ✅ **Use Real Images**: Always reference published Docker images with SHA256 hashes
2. ✅ **Test Locally**: Pull the image first to verify it exists: `docker pull mcp/server@sha256:...`
3. ✅ **Secrets Management**: Use Bitwarden or secure secret storage (see `docs/BITWARDEN_SETUP_GUIDE.md`)
4. ✅ **Version Control**: Store catalog YAML files in Git for team sharing
5. ✅ **Documentation**: Document what each server does and what secrets it needs
6. ❌ **Don't Use `:latest` tags**: Always use SHA256 hashes for reproducibility

---

## Next Steps

- **Configure Secrets**: See [`docs/BITWARDEN_SETUP_GUIDE.md`](BITWARDEN_SETUP_GUIDE.md)
- **Enable Servers**: Use Docker Desktop UI or VS Code client
- **Gateway Usage**: See [`docs/GATEWAY_SETUP.md`](GATEWAY_SETUP.md)
- **Quick Reference**: See [`docs/QUICK_REFERENCE.md`](QUICK_REFERENCE.md)
