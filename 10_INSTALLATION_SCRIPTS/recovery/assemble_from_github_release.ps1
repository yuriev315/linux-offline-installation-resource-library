<#
  ONLINE step on Windows, run from a clone of the repository. Downloads Release assets, checks each one and rebuilds
  the library files in place. Re-running skips what is already correct.
.EXAMPLE
  .\assemble_from_github_release.ps1 -Only wsl
#>
[CmdletBinding()]
param([ValidateSet('all', 'iso', 'wsl', 'apt', 'runtime')][string]$Only = 'all')
$ErrorActionPreference = 'Stop'
$Lib = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$Base = 'https://github.com/yuriev315/linux-offline-installation-resource-library/releases/download/library-2026.11.05'
$Dl = Join-Path $Lib '.release-download'
New-Item -ItemType Directory -Force -Path $Dl | Out-Null
function Test-Sha($Path, $Sha) { (Test-Path $Path) -and ((Get-FileHash -Algorithm SHA256 $Path).Hash.ToLower() -eq $Sha) }
function Test-Wanted($Name) {
  switch ($Only) {
    'all' { return $true }
    'iso' { return $Name -like '*.iso.part-*' }
    'wsl' { return $Name -like '*.wsl' }
    'apt' { return $Name -like 'apt-pool*' }
    'runtime' { return $Name -like 'language-runtimes*' }
  }
}
$rows = Get-Content (Join-Path $Lib '12_CHECKSUMS_AND_METADATA\RELEASE_MANIFEST.tsv') | ForEach-Object {
  $c = $_ -split "`t"; [pscustomobject]@{ Name = $c[0]; Sha = $c[1]; Size = [long]$c[2]; Kind = $c[3]; Target = $c[4] }
}
foreach ($r in $rows | Where-Object { Test-Wanted $_.Name }) {
  $f = Join-Path $Dl $r.Name
  if ($r.Kind -eq 'file' -and (Test-Sha (Join-Path $Lib $r.Target) $r.Sha)) { continue }
  if ($r.Kind -eq 'part' -and (Test-Path (Join-Path $Lib $r.Target))) { continue }
  if (Test-Sha $f $r.Sha) { continue }
  Write-Host "download $($r.Name)"
  & curl.exe -fL --retry 8 --retry-delay 5 -C - -o $f "$Base/$($r.Name)"
  if ($LASTEXITCODE -ne 0) { throw "download failed: $($r.Name)" }
  if (-not (Test-Sha $f $r.Sha)) { throw "SHA256 mismatch: $($r.Name)" }
}
foreach ($r in $rows | Where-Object { $_.Kind -eq 'file' -and (Test-Wanted $_.Name) }) {
  $f = Join-Path $Dl $r.Name
  if (Test-Path $f) {
    $t = Join-Path $Lib $r.Target
    New-Item -ItemType Directory -Force -Path (Split-Path $t) | Out-Null
    Move-Item -Force $f $t
  }
}
foreach ($g in $rows | Where-Object { $_.Kind -eq 'part' -and (Test-Wanted $_.Name) } | Group-Object Target) {
  $t = Join-Path $Lib $g.Name
  if (Test-Path $t) { continue }
  New-Item -ItemType Directory -Force -Path (Split-Path $t) | Out-Null
  Write-Host "assemble $t"
  $o = [IO.File]::Create("$t.tmp")
  try { foreach ($r in $g.Group | Sort-Object Name) { $i = [IO.File]::OpenRead((Join-Path $Dl $r.Name)); try { $i.CopyTo($o) } finally { $i.Dispose() } } } finally { $o.Dispose() }
  Move-Item -Force "$t.tmp" $t
}
if ($Only -in 'all', 'apt') {
  $parts = Get-ChildItem $Dl -Filter 'apt-pool.tar.part-*' | Sort-Object Name
  if ($parts) {
    $t = Join-Path $Dl 'apt-pool.tar'
    $o = [IO.File]::Create($t)
    try { foreach ($p in $parts) { $i = [IO.File]::OpenRead($p.FullName); try { $i.CopyTo($o) } finally { $i.Dispose() } } } finally { $o.Dispose() }
    & tar.exe -xf $t -C $Lib
    if ($LASTEXITCODE -ne 0) { throw 'tar failed for apt-pool.tar' }
  }
}
if ($Only -in 'all', 'runtime') {
  $t = Join-Path $Dl 'language-runtimes.tar'
  if (Test-Path $t) { & tar.exe -xf $t -C $Lib; if ($LASTEXITCODE -ne 0) { throw 'tar failed' } }
}
Write-Host 'Done. To save space, remove the .release-download folder. Fetch licence-restricted files with fetch_url_placeholders.ps1'
