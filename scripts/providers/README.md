# Provider stubs

Pick one central secrets provider and implement its fetch script. The bootstrap will read ENV vars from that provider and write Docker MCP secrets per `secrets/manifest.yaml`.

Suggested options:
- 1Password CLI (op)
- Bitwarden CLI (bw)
- Doppler (doppler)
- Infisical (infisical)
- Azure Key Vault (az)
- GitHub Encrypted Codespaces/Actions secrets (gh)
