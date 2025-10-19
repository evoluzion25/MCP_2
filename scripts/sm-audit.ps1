param(
  [string]$ProjectId,
  [string]$ProjectName = 'MCP_2'
)

$ErrorActionPreference='Stop'

function Write-Info($m){ Write-Host $m -ForegroundColor Cyan }
function Write-Ok($m){ Write-Host $m -ForegroundColor Green }
function Write-Warn($m){ Write-Host $m -ForegroundColor Yellow }

function Get-ManifestKeys() {
  $jsonPath = Join-Path $PSScriptRoot '..' 'secrets' 'manifest.json'
  if (-not (Test-Path $jsonPath)) { throw "Missing manifest: $jsonPath" }
  $mf = (Get-Content $jsonPath -Raw) | ConvertFrom-Json
  return $mf.keys.PSObject.Properties | ForEach-Object { $_.Name }
}

function Get-ProjectId($name,$explicit) {
  if ($explicit) { return $explicit }
  $idFile = Join-Path $PSScriptRoot '..' 'secrets' 'project-id.txt'
  if (Test-Path $idFile) { return (Get-Content $idFile -Raw).Trim() }
  $js = & bws project list --output json
  if ($LASTEXITCODE -ne 0) { throw 'Failed to list projects. Is BWS_ACCESS_TOKEN set?' }
  $projects = $js | ConvertFrom-Json
  $p = $projects | Where-Object { $_.name -eq $name } | Select-Object -First 1
  if (-not $p) { throw "Project not found: $name" }
  return $p.id
}

Write-Info 'Auditing Bitwarden SM project vs manifest...'
$projId = Get-ProjectId -name $ProjectName -explicit $ProjectId
Write-Ok "Project: $ProjectName ($projId)"

$need = Get-ManifestKeys | Sort-Object
$haveMap = @{}
$listJson = & bws secret list $projId --output json
if ($LASTEXITCODE -ne 0 -or -not $listJson) { throw 'Cannot list secrets from project. Check token permissions.' }
$list = $listJson | ConvertFrom-Json
foreach ($s in $list) { $haveMap[$s.key] = $true }

$present = New-Object System.Collections.Generic.List[string]
$missing = New-Object System.Collections.Generic.List[string]
foreach ($k in $need) { if ($haveMap.ContainsKey($k)) { $present.Add($k) } else { $missing.Add($k) } }

Write-Host "Present (" $present.Count "):" -NoNewline
Write-Host " " ($present -join ', ')
if ($missing.Count -gt 0) {
  Write-Warn ("Missing ({0}): {1}" -f $missing.Count, ($missing -join ', '))
} else {
  Write-Ok 'All manifest keys are present.'
}
