param([string]$Vault='default')
# Returns hashtable of key->value loaded from Bitwarden
# Requires: bw CLI authenticated (bw login / bw unlock)
$ErrorActionPreference='Stop'

# Example: export items with fields named exactly as env keys
# You can customize this to your Bitwarden organization structure.
$items = bw list items | ConvertFrom-Json
$map = @{}
foreach ($i in $items) {
  if ($i.fields) {
    foreach ($f in $i.fields) {
      if ($f.name -match '^[A-Z0-9_]+$' -and $f.value) {
        $map[$f.name] = $f.value
      }
    }
  }
}
$map | ConvertTo-Json -Compress
