$ErrorActionPreference='Stop'

param(
  [string]$ItemName = 'MCP Secrets',
  [switch]$DryRun
)

if (-not $env:BW_SESSION) {
  Write-Error "BW_SESSION not set. Run: bw login; $(([char]36))env:BW_SESSION = (bw unlock --raw)"; exit 1
}

$mfPath = Join-Path $PSScriptRoot '..' 'secrets' 'manifest.json'
if (-not (Test-Path $mfPath)) { throw "Missing manifest: $mfPath" }
$mf = (Get-Content $mfPath -Raw) | ConvertFrom-Json
$keys = $mf.keys.PSObject.Properties | ForEach-Object { $_.Name }

function Get-OrCreate-Item([string]$name){
  $items = bw list items | ConvertFrom-Json
  $existing = $items | Where-Object { $_.name -eq $name } | Select-Object -First 1
  if ($existing) { return $existing }
  if ($DryRun) { Write-Host "[DRY-RUN] Create item '$name'" -ForegroundColor Yellow; return $null }
  $tmpl = @{ type = 1; name = $name; notes = 'Secrets for MCP bootstrap'; fields = @() } | ConvertTo-Json -Depth 5
  return (bw create item --stdin $tmpl | ConvertFrom-Json)
}

function Add-BwFieldIfMissing([object]$item,[string]$fieldName){
  if (-not $item) { return }
  if (-not $item.fields) { $item.fields = @() }
  $found = $item.fields | Where-Object { $_.name -eq $fieldName } | Select-Object -First 1
  if ($found) { return }
  $field = @{ name=$fieldName; type=1; value='' }
  $item.fields += $field
}

$item = Get-OrCreate-Item -name $ItemName
if ($item) {
  foreach ($k in $keys) { Add-BwFieldIfMissing -item $item -fieldName $k }
  if ($DryRun) { Write-Host "[DRY-RUN] Update item with fields" -ForegroundColor Yellow }
  else {
    $json = $item | ConvertTo-Json -Depth 10
    $null = $json | bw edit item $item.id --stdin
    Write-Host "Seeded Bitwarden item '$ItemName' with fields." -ForegroundColor Green
  }
}

Write-Host "Done. Fill the empty field values in Bitwarden and rerun bootstrap." -ForegroundColor Cyan
