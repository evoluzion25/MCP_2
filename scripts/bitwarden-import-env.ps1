param(
  [Parameter(Mandatory=$true)][string]$EnvFile,
  [string]$ItemName = 'MCP Secrets',
  [switch]$DryRun
)

$ErrorActionPreference='Stop'

if (-not (Test-Path $EnvFile)) { throw "Env file not found: $EnvFile" }
if (-not $env:BW_SESSION) { throw "BW_SESSION not set. Run: pwsh ./scripts/bitwarden-login.ps1" }

function Get-OrCreate-ItemId([string]$name){
  $items = bw list items | ConvertFrom-Json
  $existing = $items | Where-Object { $_.name -eq $name } | Select-Object -First 1
  if ($existing) { return $existing.id }
  if ($DryRun) { Write-Host "[DRY-RUN] Create item '$name'" -ForegroundColor Yellow; return $null }
  $tmpl = (bw get template item) | ConvertFrom-Json
  $tmpl.type = 2
  $tmpl.name = $name
  $tmpl.notes = 'Secrets imported from env'
  $tmpl.secureNote = @{ type = 0 }
  $tmpl.fields = @()
  $created = ($tmpl | ConvertTo-Json -Depth 15) | bw encode | bw create item
  $obj = $created | ConvertFrom-Json
  return $obj.id
}

function Get-Item([string]$id){
  if (-not $id) { return $null }
  $json = bw get item $id
  return ($json | ConvertFrom-Json)
}

function Save-Item([object]$item){
  if (-not $item) { return }
  $payload = $item | ConvertTo-Json -Depth 15
  $null = $payload | bw encode | bw edit item $item.id
}

function Set-FieldValue([object]$item,[string]$key,[string]$value){
  if (-not $item) { return }
  if (-not $item.fields) { $item.fields = @() }
  $field = $item.fields | Where-Object { $_.name -eq $key } | Select-Object -First 1
  if (-not $field) { $field = @{ name=$key; type=1; value='' }; $item.fields += $field }
  $field.value = $value
}

$itemId = Get-OrCreate-ItemId -name $ItemName
$item = Get-Item -id $itemId

Get-Content $EnvFile | ForEach-Object {
  $line = $_.Trim()
  if (-not $line -or $line.StartsWith('#')) { return }
  $kv = $line -split '=',2
  if ($kv.Count -ne 2) { return }
  $k = $kv[0].Trim(); $v = $kv[1].Trim('"').Trim()
  if ($k -match '^[A-Z0-9_]+$' -and $v) {
    if ($DryRun) { Write-Host "[DRY-RUN] set $k" -ForegroundColor Yellow }
    else { Set-FieldValue -item $item -key $k -value $v }
  }
}

if (-not $DryRun -and $item) {
  Save-Item -item $item
  Write-Host "Imported secrets to Bitwarden item '$ItemName'." -ForegroundColor Green
}

Write-Host "Done. You can now run bootstrap-machine.ps1 -Source bitwarden" -ForegroundColor Cyan
