# Bitwarden Secret Management for MCP Servers

## Overview

This guide explains how to use Bitwarden as your centralized secret management solution for MCP servers across all devices.

## Why Bitwarden?

### Benefits
✅ **Centralized Storage**: One source of truth for all API keys and secrets  
✅ **Multi-Device Sync**: Automatic sync across all your computers  
✅ **Encrypted Vault**: Military-grade encryption with master password  
✅ **MFA Protection**: Two-factor authentication available  
✅ **No Manual Files**: No need to manage credentials.env on each device  
✅ **Audit Trail**: Track when secrets are accessed or changed  
✅ **Free Tier**: Personal use is completely free  

### How It Works

```
┌─────────────────────┐
│ credentials.env     │ (Initial import only)
│ on local machine    │
└──────────┬──────────┘
           │ Import once
           ▼
┌─────────────────────┐
│ Bitwarden Vault     │ ◄─── Your master password
│ (Cloud/Self-hosted) │      + optional 2FA
└──────────┬──────────┘
           │ Automatic sync
           ▼
┌─────────────────────┐
│ Docker MCP Secrets  │
│ on each device      │
└─────────────────────┘
           │
           ▼
┌─────────────────────┐
│ MCP Servers         │
│ (ClickUp, Brave,    │
│  HuggingFace, etc)  │
└─────────────────────┘
```

## Quick Start (One Command)

```powershell
cd C:\DevWorkspace\MCP_2

# Complete Bitwarden setup + MCP sync in one command
pwsh .\scripts\orchestrate-secrets.ps1 -EnvFile C:\DevWorkspace\credentials.env.template
```

This single command:
1. ✅ Installs Bitwarden CLI (if not installed)
2. ✅ Logs you into Bitwarden vault (interactive)
3. ✅ Imports all secrets from credentials.env to Bitwarden item "MCP Secrets"
4. ✅ Bootstraps Docker MCP secrets from Bitwarden
5. ✅ Verifies all secrets are properly configured
6. ✅ Shows you which secrets are missing (if any)

**That's it!** You only need to do this once per device.

## Step-by-Step Setup

### 1. Install Bitwarden

```powershell
# Option A: Use our installer script (recommended)
pwsh C:\DevWorkspace\MCP_2\scripts\install-bitwarden.ps1

# Option B: Manual install
winget install Bitwarden.Bitwarden     # Desktop app
winget install Bitwarden.CLI           # Command-line tool
```

### 2. Create Bitwarden Account (First Time Only)

If you don't have a Bitwarden account:
1. Go to https://vault.bitwarden.com/
2. Click "Create Account"
3. Choose a strong master password (you'll need this!)
4. Optional but recommended: Enable 2FA in Settings → Security

### 3. Login and Unlock

```powershell
# Interactive login (first time on new device)
pwsh C:\DevWorkspace\MCP_2\scripts\bitwarden-login.ps1

# Or manually:
bw login
# Enter your email and master password

# Unlock and set session (needed after restart)
$env:BW_SESSION = (bw unlock --raw)
# Enter your master password
```

**Important**: The `BW_SESSION` environment variable is needed for the scripts to work. It expires when you close PowerShell.

### 4. Import Secrets from credentials.env to Bitwarden

```powershell
# Import all secrets to Bitwarden item "MCP Secrets"
pwsh C:\DevWorkspace\MCP_2\scripts\bitwarden-import-env.ps1 `
    -EnvFile C:\DevWorkspace\credentials.env.template `
    -ItemName "MCP Secrets"

# Test run first (recommended)
pwsh C:\DevWorkspace\MCP_2\scripts\bitwarden-import-env.ps1 `
    -EnvFile C:\DevWorkspace\credentials.env.template `
    -ItemName "MCP Secrets" `
    -DryRun
```

This creates a Secure Note in your Bitwarden vault with all your API keys as custom fields.

### 5. Bootstrap Docker MCP from Bitwarden

```powershell
# Sync secrets from Bitwarden to Docker MCP
pwsh C:\DevWorkspace\MCP_2\scripts\bootstrap-machine.ps1 -Source bitwarden

# Or test first
pwsh C:\DevWorkspace\MCP_2\scripts\bootstrap-machine.ps1 -Source bitwarden -DryRun
```

### 6. Verify Setup

```powershell
# Check which secrets are configured
pwsh C:\DevWorkspace\MCP_2\scripts\check-readiness.ps1

# Or manually check
docker mcp secret list
```

## Using Bitwarden on Multiple Devices

### First Device (Primary Setup)

```powershell
# Run the full orchestration
pwsh C:\DevWorkspace\MCP_2\scripts\orchestrate-secrets.ps1 `
    -EnvFile C:\DevWorkspace\credentials.env.template
```

### Additional Devices (No credentials.env needed!)

```powershell
cd C:\DevWorkspace\MCP_2

# 1. Install Bitwarden CLI
pwsh .\scripts\install-bitwarden.ps1

# 2. Login (your vault already has all secrets!)
pwsh .\scripts\bitwarden-login.ps1

# 3. Bootstrap from Bitwarden (no env file needed)
pwsh .\scripts\bootstrap-machine.ps1 -Source bitwarden

# 4. Verify
pwsh .\scripts\check-readiness.ps1
```

**That's it!** No need to copy credentials.env to each device.

## Managing Secrets in Bitwarden

### View Your Secrets

```powershell
# List all items
bw list items

# View the MCP Secrets item
bw get item "MCP Secrets"

# Or use the Bitwarden Desktop app or web vault
```

### Update a Secret

**Option A: Via Bitwarden Web/Desktop App**
1. Open https://vault.bitwarden.com/ or desktop app
2. Find "MCP Secrets" item
3. Edit the field (e.g., `BRAVE_API_KEY`)
4. Save
5. Re-sync on each device:
   ```powershell
   $env:BW_SESSION = (bw unlock --raw)
   pwsh .\scripts\bootstrap-machine.ps1 -Source bitwarden
   ```

**Option B: Via CLI**
```powershell
# Get the item
$item = bw get item "MCP Secrets" | ConvertFrom-Json

# Update a field (example: new Brave API key)
$field = $item.fields | Where-Object { $_.name -eq "BRAVE_API_KEY" }
$field.value = "new_brave_api_key_here"

# Save back
$item | ConvertTo-Json -Depth 10 | bw encode | bw edit item $item.id

# Re-sync to Docker MCP
pwsh .\scripts\bootstrap-machine.ps1 -Source bitwarden
```

### Add a New Secret

```powershell
# 1. Add to credentials.env.template (for documentation)
# 2. Re-import to Bitwarden
pwsh .\scripts\bitwarden-import-env.ps1 -EnvFile C:\DevWorkspace\credentials.env.template

# 3. Add mapping to manifest
# Edit: C:\DevWorkspace\MCP_2\secrets\manifest.yaml
# Add:
#   TAVILY_API_KEY:
#     mcp: tavily.api_token

# 4. Re-bootstrap
pwsh .\scripts\bootstrap-machine.ps1 -Source bitwarden
```

## Secret Mapping Reference

The `secrets/manifest.yaml` file maps environment variable names to Docker MCP secret names:

```yaml
keys:
  BRAVE_API_KEY:           # From credentials.env
    mcp: brave.api_key     # To Docker MCP
  
  CLICKUP_API_KEY:
    mcp: clickup.api_key
  
  CLICKUP_TEAM_ID:
    mcp: clickup.team_id
  
  # ... etc
```

## Supported Secrets

Currently mapped in `manifest.yaml`:

### Search & Research
- `BRAVE_API_KEY` → `brave.api_key`
- `EXA_API_KEY` → `exa.api_key`

### Task Management  
- `CLICKUP_API_KEY` → `clickup.api_key`
- `CLICKUP_TEAM_ID` → `clickup.team_id`

### AI Services
- `OPENAI_API_KEY` → `openai.api_key`
- `ANTHROPIC_API_KEY` → `anthropic.api_key`
- `GEMINI_API_KEY` → `gemini.api_key`
- `PERPLEXITY_API_KEY` → `perplexity.api_key`
- `HF_TOKEN` → `huggingface.token`

### Infrastructure
- `CLOUDFLARE_API_KEY` → `cloudflare.api_key`
- `RUNPOD_API_KEY2` → `runpod.api_key2`
- `RUNPOD_PASSKEY` → `runpod.passkey`
- `RUNPOD_S3_KEY2` → `runpod.s3_key`
- `RUNPOD_S3_KEY2_USER` → `runpod.s3_user`

### Storage
- `GCS_ACCESS_KEY` → `gcs.access_key`
- `GCS_SECRET_KEY` → `gcs.secret_key`
- `GCS_BUCKET` → `gcs.bucket`

### Development
- `GITHUB_TOKEN` → `github-server.token`
- `RG_API_KEY` → `rg.api_key`

### Other
- `SSH_KEY_1` → `ssh.key_1`
- `SSH_KEY_2` → `ssh.key_2`
- `DIGITALOCEAN_API_KEY` → `digitalocean.api_key`
- `HEROKU_API_KEY` → `heroku.api_key`
- `GODADDY_API_KEY` → `godaddy.api_key`

## Troubleshooting

### "BW_SESSION not set"

```powershell
# Unlock your vault
$env:BW_SESSION = (bw unlock --raw)
# Enter your master password
```

### "bw: command not found"

```powershell
# Install Bitwarden CLI
pwsh C:\DevWorkspace\MCP_2\scripts\install-bitwarden.ps1

# Or manually
winget install Bitwarden.CLI
```

### Session Expired

The `BW_SESSION` expires after a period of inactivity or when you close PowerShell.

```powershell
# Re-unlock
$env:BW_SESSION = (bw unlock --raw)

# Or logout and login again
bw logout
pwsh C:\DevWorkspace\MCP_2\scripts\bitwarden-login.ps1
```

### "Item 'MCP Secrets' not found"

```powershell
# Create it by importing from env file
pwsh C:\DevWorkspace\MCP_2\scripts\bitwarden-import-env.ps1 `
    -EnvFile C:\DevWorkspace\credentials.env.template
```

### Secrets Not Syncing to Docker MCP

```powershell
# Check Bitwarden session
bw status

# Verify item exists
bw get item "MCP Secrets"

# Re-run bootstrap
$env:BW_SESSION = (bw unlock --raw)
pwsh C:\DevWorkspace\MCP_2\scripts\bootstrap-machine.ps1 -Source bitwarden

# Check Docker MCP secrets
docker mcp secret list
```

### Want to Use Multiple Bitwarden Items

Edit `scripts/bootstrap-machine.ps1` or use collection filtering. Default setup uses one item named "MCP Secrets" with all secrets as custom fields.

## Security Best Practices

### Master Password
- ✅ Use a strong, unique master password (12+ characters)
- ✅ Store it securely (password manager, written down in safe)
- ❌ Don't reuse it for other services
- ❌ Don't share it with anyone

### Two-Factor Authentication
```
1. Open Bitwarden web vault
2. Settings → Security → Two-step Login
3. Enable Authenticator App (Google Authenticator, Authy, etc.)
4. Save backup codes in a safe place
```

### Session Management
```powershell
# Lock vault when not in use
bw lock

# Logout when leaving computer
bw logout

# Set session timeout (optional)
# In Bitwarden app: Settings → Vault timeout → 15 minutes
```

### Audit Trail
```powershell
# Check when you last logged in
bw status

# View sync status
bw sync
```

## Legacy Method (Not Recommended)

If you don't want to use Bitwarden, you can still use direct sync:

```powershell
# Direct sync from credentials.env (legacy)
pwsh C:\DevWorkspace\MCP_2\scripts\sync-secrets.ps1 `
    -EnvFile C:\DevWorkspace\credentials.env.template

# Or with setup script
pwsh C:\DevWorkspace\MCP_2\scripts\setup-production-servers.ps1 -UseLegacySync
```

**Limitations:**
- ❌ Manual credential file management
- ❌ No automatic cross-device sync
- ❌ No encryption at rest
- ❌ No audit trail
- ❌ No MFA protection

## FAQ

**Q: Can I use self-hosted Bitwarden?**  
A: Yes! Configure `bw config server https://your-bitwarden-url.com` before login.

**Q: What if I forget my master password?**  
A: There's no recovery. Keep a backup of your credentials.env file somewhere safe until you're confident in your Bitwarden setup.

**Q: Can multiple people share these secrets?**  
A: Yes, use Bitwarden Organizations for team sharing. You'll need to modify the scripts slightly.

**Q: Is this more secure than credentials.env?**  
A: Yes, significantly:
- Encrypted vault with master password
- Optional 2FA
- Audit logging
- No plaintext files on disk

**Q: Does this work on Linux/Mac?**  
A: Yes, but you'll need to adapt the PowerShell scripts to bash/zsh. The Bitwarden CLI works identically across platforms.

**Q: Can I have different secrets per project?**  
A: Yes, create multiple Bitwarden items (e.g., "MCP Secrets Dev", "MCP Secrets Prod") and modify the scripts to use different item names.

## Resources

- **Bitwarden**: https://bitwarden.com
- **CLI Documentation**: https://bitwarden.com/help/cli/
- **MCP_2 Scripts**: `C:\DevWorkspace\MCP_2\scripts\`
- **Manifest File**: `C:\DevWorkspace\MCP_2\secrets\manifest.yaml`

---

**Recommended Workflow**: 
```powershell
# First time setup
pwsh C:\DevWorkspace\MCP_2\scripts\orchestrate-secrets.ps1 -EnvFile C:\DevWorkspace\credentials.env.template

# Daily use (after restarting PowerShell)
$env:BW_SESSION = (bw unlock --raw)

# New device
pwsh C:\DevWorkspace\MCP_2\scripts\bootstrap-machine.ps1 -Source bitwarden
```
