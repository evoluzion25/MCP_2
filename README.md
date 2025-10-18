# MCP_2

Infrastructure-as-code for managing MCP servers via Docker Desktop (DD), served locally to clients (VS Code, etc.) and optionally exposed through Cloudflare Tunnel.

## Goals
- Define, build, and manage all MCP servers with Docker MCP catalogs
- Connect local clients (VS Code) via `docker mcp client connect`
- Support custom servers via catalog import/add
- Optional: expose gateway over Cloudflare Tunnel

## Quick start
1. Ensure Docker Desktop v28+ with MCP CLI: `docker mcp version`
2. Connect VS Code client:
   - `docker mcp client connect vscode`
3. Bootstrap a starter catalog and view it:
   - `docker mcp catalog bootstrap ./catalogs/starter.yaml`
   - `docker mcp catalog show --format yaml`
4. Run the gateway (loads official + imported catalogs):
   - `docker mcp gateway run`

See `docs/catalog-howto.md` for managing catalogs and adding custom servers, and `docs/cloudflare-tunnel.md` for tunnel setup.
