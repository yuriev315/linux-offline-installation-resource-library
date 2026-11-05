<# Check VMware Workstation and create a VM from a template in 03_VMWARE\vm_templates. Run in PowerShell on the Windows host.
   Existing VM folders are never overwritten. Unattended ISO installation is not attempted: complete the Ubuntu installer in the VM window.
.EXAMPLE
  .\create_vmware_vm.ps1 -Kind server -VmDir D:\VMs\ubuntu-2404-server
  .\create_vmware_vm.ps1 -CheckOnly
#>
[CmdletBinding()]
param(
  [ValidateSet('desktop', 'server')][string]$Kind = 'server',
  [string]$VmDir,
  [int]$DiskGB = 0,
  [switch]$CheckOnly,
  [switch]$PowerOn
)
$ErrorActionPreference = 'Stop'
$Lib = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$candidates = @("${env:ProgramFiles}\VMware\VMware Workstation", "${env:ProgramFiles(x86)}\VMware\VMware Workstation")
$vmw = $candidates | Where-Object { Test-Path (Join-Path $_ 'vmware.exe') } | Select-Object -First 1
if (-not $vmw) { throw 'VMware Workstation not found. Install it first: see 03_VMWARE\workstation_installers\HOW_TO_OBTAIN.md' }
$ver = (Get-Item (Join-Path $vmw 'vmware.exe')).VersionInfo.ProductVersion
Write-Host "VMware Workstation $ver at $vmw"
foreach ($n in 'VMware NAT Service', 'VMnetDHCP') { $s = Get-Service -DisplayName $n -ErrorAction SilentlyContinue; if ($s) { Write-Host "$n : $($s.Status)" } }
if ($CheckOnly) { exit 0 }
if (-not $VmDir) { throw '-VmDir is required' }
$iso = if ($Kind -eq 'desktop') { Join-Path $Lib '01_UBUNTU_ISO\ubuntu_desktop\ubuntu-24.04.5.1-desktop-amd64.iso' } else { Join-Path $Lib '01_UBUNTU_ISO\ubuntu_server\ubuntu-24.04.5-live-server-amd64.iso' }
if (-not (Test-Path $iso)) { throw "ISO not found: $iso" }
if (Test-Path $VmDir) { throw "Refusing to touch existing folder: $VmDir" }
if ($DiskGB -eq 0) { $DiskGB = if ($Kind -eq 'desktop') { 80 } else { 40 } }
New-Item -ItemType Directory -Path $VmDir | Out-Null
$name = Split-Path $VmDir -Leaf
& (Join-Path $vmw 'vmware-vdiskmanager.exe') -c -s "${DiskGB}GB" -a nvme -t 0 (Join-Path $VmDir "$name.vmdk")
if ($LASTEXITCODE -ne 0) { throw 'vmware-vdiskmanager failed' }
$vmx = Join-Path $VmDir "$name.vmx"
(Get-Content (Join-Path $Lib "03_VMWARE\vm_templates\ubuntu-2404-$Kind.vmx.template")) -replace '@NAME@', $name -replace '@ISO@', $iso | Set-Content -Encoding ascii $vmx
Write-Host "Created $vmx"
if ($PowerOn) { & (Join-Path $vmw 'vmrun.exe') -T ws start $vmx gui }
