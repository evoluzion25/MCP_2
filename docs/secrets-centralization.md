# Centralizing secrets across devices

You have a few durable options to keep one source of truth and sync into Docker MCP locally on any machine.

## Option A: Single plain env file (fastest, manual)
- Keep `C:\DevWorkspace\credentials.env` as your canonical file.
- Sync into MCP with: `pwsh ./scripts/sync-secrets.ps1`
- Pros: simple, offline. Cons: manual distribution, store carefully.

## Option B: Git-ignored env per device + manifest
- Keep a sanitized template in your repo (already done).
- Each device maintains a private `credentials.env` (git-ignored).
- Use `./scripts/update-env-from-secrets.ps1` to ensure keys exist.

## Option C: Central secrets manager (recommended)
Pick one as the online source of truth, then run a bootstrap per device. Free and CLI-friendly: Bitwarden.

Bitwarden quickstart (PowerShell):
- Install: winget install Bitwarden.Bitwarden && winget install Bitwarden.CLI
- Login: bw login
- Unlock: $env:BW_SESSION = (bw unlock --raw)
- Verify: bw list items | Out-Null
- Bootstrap into Docker MCP: pwsh ./scripts/bootstrap-machine.ps1 -Source bitwarden

How it works:
1) You store secrets centrally.
2) On a new device, run:
   - `pwsh ./scripts/bootstrap-machine.ps1 -Source bitwarden` (example)
3) The bootstrap reads `secrets/manifest.yaml` to map keys → MCP secret names and writes them into Docker MCP.

## Manifest mapping
- Edit `secrets/manifest.yaml` to add/update mappings.
- This keeps CLI names stable while you can change underlying providers.

## Security tips
- Never commit real secrets. Templates with placeholders only.
- Prefer a secrets manager with MFA and device approvals.
- Rotate keys regularly and keep least-privilege per service.
