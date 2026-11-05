<# Export a WSL distro to a tar file. Refuses to overwrite an existing backup.
.EXAMPLE
  .\wsl_backup.ps1 -DistroName Ubuntu-24.04 -OutFile D:\Backup\ubuntu-2404.tar
#>
param([Parameter(Mandatory)][string]$DistroName, [Parameter(Mandatory)][string]$OutFile)
$ErrorActionPreference = 'Stop'
if (Test-Path $OutFile) { throw "Refusing to overwrite $OutFile" }
& wsl.exe --terminate $DistroName
& wsl.exe --export $DistroName $OutFile
if ($LASTEXITCODE -ne 0) { throw "wsl --export failed with code $LASTEXITCODE" }
$h = (Get-FileHash -Algorithm SHA256 $OutFile).Hash.ToLower()
Set-Content -Path "$OutFile.sha256" -Value "$h  $(Split-Path $OutFile -Leaf)"
Write-Host "Backup: $OutFile  SHA256: $h"
