# Cloudflare Tunnel with Docker MCP Gateway

This outlines exposing the Docker MCP Gateway over a Cloudflare Tunnel.

## Overview
- Run the MCP Gateway locally: `docker mcp gateway run`
- Expose the gateway stdio or HTTP endpoint via Cloudflare Tunnel.
- Secure with Cloudflare Access or mTLS if exposing beyond your LAN.

## Steps (high level)
1. Install Cloudflare Tunnel (cloudflared) on your machine.
2. Authenticate: `cloudflared login` and select your zone.
3. Create a named tunnel: `cloudflared tunnel create mcp-gateway`
4. Determine gateway endpoint:
   - Default gateway uses stdio for clients; for remote access, run via HTTP mode if supported in your environment.
   - Alternatively, run a reverse proxy container that terminates HTTP and forwards to gateway.
5. Configure tunnel routing:
   - `cloudflared tunnel route dns mcp-gateway mcp.example.com`
6. Configure `config.yml` for the tunnel to point to your local gateway service.
7. Run: `cloudflared tunnel run mcp-gateway`

Notes:
- Keep secrets out of the repo; use Docker MCP secrets or environment files.
- Consider Access policies to restrict who can reach the endpoint.
