<# Restore a backup under a NEW distro name. Existing distros and non-empty folders are never touched.
.EXAMPLE
  .\wsl_restore.ps1 -BackupFile D:\Backup\ubuntu-2404.tar -DistroName Ubuntu-24.04-restored -InstallDir D:\WSL\restored
#>
param([Parameter(Mandatory)][string]$BackupFile, [Parameter(Mandatory)][string]$DistroName, [Parameter(Mandatory)][string]$InstallDir)
$ErrorActionPreference = 'Stop'
if (-not (Test-Path $BackupFile)) { throw "Not found: $BackupFile" }
if (Test-Path "$BackupFile.sha256") {
  $want = ((Get-Content "$BackupFile.sha256") -split '\s+')[0]
  if ((Get-FileHash -Algorithm SHA256 $BackupFile).Hash.ToLower() -ne $want) { throw 'Backup checksum mismatch' }
}
$existing = (& wsl.exe --list --quiet) -replace "`0", '' | Where-Object { $_ }
if ($existing -contains $DistroName) { throw "Distro '$DistroName' already exists; choose another name." }
if ((Test-Path $InstallDir) -and (Get-ChildItem $InstallDir -Force | Select-Object -First 1)) { throw "InstallDir is not empty: $InstallDir" }
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
& wsl.exe --import $DistroName $InstallDir $BackupFile --version 2
if ($LASTEXITCODE -ne 0) { throw "wsl --import failed with code $LASTEXITCODE" }
Write-Host "Restored as $DistroName"
