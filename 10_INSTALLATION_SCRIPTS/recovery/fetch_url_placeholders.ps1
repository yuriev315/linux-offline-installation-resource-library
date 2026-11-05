<#
  ONLINE step on Windows. Fetch the licence-restricted files named by the .url placeholders, directly from their
  publishers, and check each SHA256. Files that need a sign-in are listed for you to download by hand. Safe to re-run.
.EXAMPLE
  .\fetch_url_placeholders.ps1 -Only wsl
#>
[CmdletBinding()]
param([ValidateSet('all', 'vmware', 'wsl', 'vscode')][string]$Only = 'all')
$ErrorActionPreference = 'Stop'
$Lib = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$roots = switch ($Only) { 'vmware' { @('03_VMWARE') } 'wsl' { @('02_WSL2') } 'vscode' { @('15_DEVELOPMENT_ENVIRONMENT') } default { @('02_WSL2', '03_VMWARE', '15_DEVELOPMENT_ENVIRONMENT') } }
function Get-Field($Text, $Name) { ($Text | Where-Object { $_ -like "$Name=*" } | Select-Object -First 1) -replace "^$Name=", '' }
$ok = 0; $manual = 0; $failed = 0
foreach ($u in $roots | ForEach-Object { Get-ChildItem (Join-Path $Lib $_) -Recurse -Filter *.url }) {
  $text = Get-Content -LiteralPath $u.FullName
  $dst = $u.FullName -replace '\.url$', ''; $want = Get-Field $text 'SHA256'; $url = Get-Field $text 'URL'
  if ((Test-Path -LiteralPath $dst) -and ((Get-FileHash -LiteralPath $dst -Algorithm SHA256).Hash.ToLower() -eq $want)) { Write-Host "have      $dst"; $ok++; continue }
  if ((Get-Field $text 'DirectDownload') -ne 'yes') { Write-Host "BY HAND   $dst`n          $url`n          SHA256 must be $want"; $manual++; continue }
  Write-Host "download  $dst"
  & curl.exe -fL --retry 5 --retry-delay 5 --compressed -o "$dst.part" $url
  if (($LASTEXITCODE -eq 0) -and ((Get-FileHash -LiteralPath "$dst.part" -Algorithm SHA256).Hash.ToLower() -eq $want)) { Move-Item -Force -LiteralPath "$dst.part" $dst; $ok++ }
  else { Write-Warning "FAILED $dst (download error or SHA256 mismatch; the publisher may have replaced this version)"; $failed++ }
}
Write-Host "ready=$ok by_hand=$manual failed=$failed"
if ($failed) { exit 1 }
