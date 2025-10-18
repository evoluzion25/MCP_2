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
For one place to keep secrets across devices, see `docs/secrets-centralization.md`.

## Credentials integration with dev-env-config
Keep your secrets centralized in `C:\DevWorkspace\credentials.env` from the dev-env-config repo. Then sync them into Docker MCP secrets:

- `scripts/sync-secrets.ps1` (reads `C:\DevWorkspace\credentials.env` by default)
  - Maps keys like `BRAVE_API_KEY`, `EXA_API_KEY`, `GITHUB_TOKEN` to MCP secret names (`brave.api_key`, `exa.api_key`, `github-server.token`).
  - Use `-DryRun` to preview without writing.

Example:
- `pwsh ./scripts/sync-secrets.ps1`

Keep the env file current with any known keys from secrets (values not exposed):
- `pwsh ./scripts/update-env-from-secrets.ps1`

## Bitwarden setup (central secrets manager)
- Install: `pwsh ./scripts/install-bitwarden.ps1`
- Login + unlock + set session: `pwsh ./scripts/bitwarden-login.ps1`
- Seed a template item with required fields: `pwsh ./scripts/bitwarden-seed.ps1 -ItemName "MCP Secrets"`
- Bootstrap secrets into Docker MCP: `pwsh ./scripts/bootstrap-machine.ps1 -Source bitwarden`

Additional secret mappings supported:
- OPENAI_API_KEY, ANTHROPIC_API_KEY, GEMINI_API_KEY, PERPLEXITY_API_KEY
- CLOUDFLARE_API_KEY, CLICKUP_API_KEY
- HF_TOKEN, RG_API_KEY
- RUNPOD_PASSKEY, RUNPOD_API_KEY2, RUNPOD_S3_KEY2_USER, RUNPOD_S3_KEY2
- GCS_ACCESS_KEY, GCS_SECRET_KEY, GCS_BUCKET

Service templates:
- `catalogs/service-templates.yaml` contains placeholders for common services with standard secret names. Import this file or copy entries you need into your own catalog, then run:
   - `docker mcp catalog import .\catalogs\service-templates.yaml`
