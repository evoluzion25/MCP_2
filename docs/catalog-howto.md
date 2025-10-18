# Catalog management how-to

This repo shows how to manage MCP servers using Docker MCP catalogs.

## Prereqs
- Docker Desktop 28+
- Docker MCP CLI available (`docker mcp`)

## Common commands
- List catalogs
  - `docker mcp catalog ls`
- Create empty catalog
  - `docker mcp catalog create my-catalog`
- Bootstrap starter catalog with examples
  - `docker mcp catalog bootstrap ./catalogs/starter.yaml`
- Show catalog content
  - `docker mcp catalog show [catalog] --format yaml`
- Import a catalog file or URL
  - `docker mcp catalog import ./catalogs/custom_catalog.yaml`
  - `docker mcp catalog import https://example.com/catalog.yaml`
- Add a server from a file into a catalog
  - `docker mcp catalog add my-catalog github-server ./catalogs/github-server.yaml`
  - Use `--force` to overwrite.
- Reset catalogs (removes custom catalogs)
  - `docker mcp catalog reset`

## Custom catalog templates
See `catalogs/custom_catalog.yaml` for a template. Edit values as needed.

## Using in VS Code
- Connect: `docker mcp client connect vscode`
- Restart VS Code if prompted.
- Tools become available via the MCP gateway.

## References
- Docker MCP Catalog docs: https://github.com/docker/mcp-gateway/blob/main/docs/catalog.md
- CLI reference: https://docs.docker.com/reference/cli/docker/mcp/catalog/catalog_add/
