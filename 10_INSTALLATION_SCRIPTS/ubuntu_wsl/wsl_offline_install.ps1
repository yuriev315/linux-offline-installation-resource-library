<#
.SYNOPSIS
  Offline WSL2 + Ubuntu 24.04.5 install, without the Microsoft Store. Run in an elevated PowerShell.
  Safe to re-run. Stage 1 enables Windows features (reboot); run it again after the reboot for stage 2.
.EXAMPLE
  .\wsl_offline_install.ps1 -DistroName Ubuntu-24.04 -InstallDir D:\WSL\Ubuntu-24.04 -User dev
#>
[CmdletBinding()]
param(
  [string]$DistroName = 'Ubuntu-24.04',
  [string]$InstallDir = "$env:USERPROFILE\WSL\Ubuntu-24.04",
  [string]$User,
  [switch]$CheckOnly
)
$ErrorActionPreference = 'Stop'
$Lib = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$Msi = Join-Path $Lib '02_WSL2\wsl_installers\wsl.3.0.3.0.x64.msi'
$Rootfs = Join-Path $Lib '02_WSL2\ubuntu_rootfs\ubuntu-24.04.5-wsl-amd64.wsl'
$MsiSha = 'ae977286974255bd26bf925f00f40f5692c6b2084155cbc0563c09aea091f211'
$RootfsSha = 'bb415d824822c4b878125729af451a5d18fb13d1cf5cbed9a7393ad64ac6039e'
$Log = Join-Path $env:TEMP 'wsl_offline_install.log'
function Say($m) { $l = "$(Get-Date -Format s) $m"; Write-Host $l; Add-Content -Path $Log -Value $l }

$principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { throw 'Run this in an elevated PowerShell.' }

# --- checks
$build = [int](Get-CimInstance Win32_OperatingSystem).BuildNumber
Say "Windows build $build, arch $env:PROCESSOR_ARCHITECTURE"
if ($env:PROCESSOR_ARCHITECTURE -ne 'AMD64') { throw 'This library carries the x64 WSL package only.' }
if ($build -lt 19041) { throw 'The WSL MSI package needs Windows 10 2004 (build 19041) or later. Update Windows first.' }
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$hv = (Get-CimInstance Win32_ComputerSystem).HypervisorPresent
Say "Firmware virtualization enabled: $($cpu.VirtualizationFirmwareEnabled); hypervisor already running: $hv"
if (-not $cpu.VirtualizationFirmwareEnabled -and -not $hv) { throw 'Virtualization is off. Enable Intel VT-x / AMD-V in BIOS or UEFI. WSL2 cannot run without it.' }
foreach ($f in @(@($Msi, $MsiSha), @($Rootfs, $RootfsSha))) {
  if (-not (Test-Path $f[0])) { throw "Missing file: $($f[0]). While online, run 10_INSTALLATION_SCRIPTS\recovery\fetch_url_placeholders.ps1 and assemble_from_github_release.ps1" }
  $got = (Get-FileHash -Algorithm SHA256 $f[0]).Hash.ToLower()
  if ($got -ne $f[1]) { throw "SHA256 mismatch: $($f[0])" }
  Say "SHA256 OK: $(Split-Path $f[0] -Leaf)"
}
if ($CheckOnly) { Say 'Checks passed; nothing changed (-CheckOnly).'; exit 0 }

# --- stage 1: Windows features. WSL2 needs both; WSL1 would need only the first.
$needReboot = $false
foreach ($feature in 'Microsoft-Windows-Subsystem-Linux', 'VirtualMachinePlatform') {
  $state = (Get-WindowsOptionalFeature -Online -FeatureName $feature).State
  Say "Feature ${feature}: $state"
  if ($state -ne 'Enabled') {
    & dism.exe /online /enable-feature /featurename:$feature /all /norestart | Out-Null
    if ($LASTEXITCODE -notin 0, 3010) { throw "dism failed for $feature with code $LASTEXITCODE" }
    $needReboot = $true
  }
}
if ($needReboot) { Say 'Windows features enabled. REBOOT, then run this script again.'; exit 3010 }

# --- stage 2: WSL package. The modern MSI includes the WSL2 kernel, so wsl_update_x64.msi is not needed here.
$wslExe = Join-Path $env:ProgramFiles 'WSL\wsl.exe'
if (Test-Path $wslExe) {
  Say "WSL package already installed: $wslExe"
} else {
  $p = Start-Process msiexec.exe -Wait -PassThru -ArgumentList @('/i', "`"$Msi`"", '/qn', '/norestart', '/l*v', "`"$env:TEMP\wsl_msi.log`"")
  if ($p.ExitCode -notin 0, 3010) { throw "msiexec failed with code $($p.ExitCode); see $env:TEMP\wsl_msi.log" }
  Say 'WSL package installed.'
}
& $wslExe --set-default-version 2 | Out-Null

# --- stage 3: import. Never overwrites an existing distro.
$existing = (& $wslExe --list --quiet) -replace "`0", '' | Where-Object { $_ }
if ($existing -contains $DistroName) {
  Say "Distro '$DistroName' already exists; import skipped."
} else {
  if ((Test-Path $InstallDir) -and (Get-ChildItem $InstallDir -Force | Select-Object -First 1)) { throw "InstallDir is not empty: $InstallDir" }
  New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
  & $wslExe --import $DistroName $InstallDir $Rootfs --version 2
  if ($LASTEXITCODE -ne 0) { throw "wsl --import failed with code $LASTEXITCODE" }
  Say "Imported '$DistroName' into $InstallDir"
}

# --- stage 4: .wslconfig, only if the user has none
$cfg = Join-Path $env:USERPROFILE '.wslconfig'
if (Test-Path $cfg) { Say "Keeping existing $cfg" } else {
  Copy-Item (Join-Path $Lib '11_CONFIGURATIONS\wsl\wslconfig.template') $cfg
  Say "Wrote $cfg; edit memory, processors and swap to suit this PC."
}

# --- stage 5: user and offline packages
if ($User) {
  $linuxLib = (& $wslExe -d $DistroName -u root -- wslpath -a "$($Lib -replace '\\','/')").Trim()
  & $wslExe -d $DistroName -u root -- bash "$linuxLib/10_INSTALLATION_SCRIPTS/ubuntu_wsl/wsl_configure_distro.sh" --user $User
  if ($LASTEXITCODE -ne 0) { throw "In-distro setup failed with code $LASTEXITCODE" }
  & $wslExe --terminate $DistroName
}
Say "Finished. Start with: wsl -d $DistroName"
