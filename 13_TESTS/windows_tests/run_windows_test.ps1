<# Real Windows test on a machine with no network. Runs at each logon until every stage is done, then shuts down.
   Stages: syntax > VMware install > VMware VM tests > WSL features > WSL install, verify, backup, restore. #>
$ErrorActionPreference = 'Continue'
$payload = (Get-PSDrive -PSProvider FileSystem | Where-Object { Test-Path ($_.Root + 'OFFLINE_TEST_PAYLOAD') } | Select-Object -First 1).Root
$Lib = Join-Path $payload 'Linux_Offline_Installation_Resource_Library'
$Res = Join-Path $payload 'test_results'; New-Item -ItemType Directory -Force -Path $Res | Out-Null
$Work = 'C:\offline_test'; New-Item -ItemType Directory -Force -Path $Work | Out-Null
$StageFile = Join-Path $Work 'stage.txt'
$Stage = if (Test-Path $StageFile) { [int](Get-Content $StageFile) } else { 0 }
Start-Transcript -Path (Join-Path $Res "stage$Stage.log") -Append | Out-Null
function Say($m) { Write-Host "=== $(Get-Date -Format s) $m" }
function Result($name, $ok, $detail = '') { $s = if ($ok) { 'PASS' } else { 'FAIL' }; $l = "$s $name $detail"; Write-Host $l; Add-Content -Path (Join-Path $Res 'results.txt') -Value $l }
function Next($n, [switch]$Reboot) { Set-Content $StageFile $n; Stop-Transcript | Out-Null; if ($Reboot) { Restart-Computer -Force; Start-Sleep 300 } else { & $PSCommandPath; exit } }
$me = $PSCommandPath

if ($Stage -eq 0) {
  Say 'prepare the test machine'
  Get-CimInstance Win32_OperatingSystem | Format-List Caption, Version, BuildNumber
  Get-NetAdapter -ErrorAction SilentlyContinue | Format-Table Name, Status
  Result 'no-network-adapter' (-not (Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object Status -eq 'Up'))
  Result 'no-internet' (-not (Test-Connection -ComputerName 185.125.190.81 -Count 1 -Quiet -ErrorAction SilentlyContinue))
  $a = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$me`""
  Register-ScheduledTask -TaskName OfflineTest -Force -RunLevel Highest -Trigger (New-ScheduledTaskTrigger -AtLogOn -User tester) -Action (New-ScheduledTaskAction -Execute powershell.exe -Argument $a) -Settings (New-ScheduledTaskSettingsSet -ExecutionTimeLimit ([TimeSpan]::Zero) -AllowStartIfOnBatteries) | Out-Null
  powercfg -change -standby-timeout-ac 0; powercfg -change -monitor-timeout-ac 0; powercfg -h off
  Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue
  reg add HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard /v EnableVirtualizationBasedSecurity /t REG_DWORD /d 0 /f | Out-Null
  reg add HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity /v Enabled /t REG_DWORD /d 0 /f | Out-Null
  Say 'PowerShell syntax of every script in the library'
  & (Join-Path $Lib '10_INSTALLATION_SCRIPTS\integrity_verification\verify_powershell_syntax.ps1'); Result 'powershell-syntax' ($LASTEXITCODE -eq 0)
  Say 'WSL script, check only'
  & (Join-Path $Lib '10_INSTALLATION_SCRIPTS\ubuntu_wsl\wsl_offline_install.ps1') -CheckOnly; Result 'wsl-checkonly' ($LASTEXITCODE -eq 0) "rc=$LASTEXITCODE"
  Next 1 -Reboot
}

if ($Stage -eq 1) {
  Say 'install VMware Workstation from the local file'
  $exe = Get-ChildItem (Join-Path $Lib '03_VMWARE\workstation_installers\VMware-Workstation-Full-*.exe') | Select-Object -First 1
  $sig = Get-AuthenticodeSignature $exe.FullName; Write-Host "$($sig.Status) $($sig.SignerCertificate.Subject)"
  Result 'vmware-signature' ($sig.Status -eq 'Valid' -and $sig.SignerCertificate.Subject -match 'Broadcom') $sig.Status
  $p = Start-Process -FilePath $exe.FullName -Wait -PassThru -ArgumentList '/s', "/v`"/qn EULAS_AGREED=1 AUTOSOFTWAREUPDATE=0 DATACOLLECTION=0 ADDLOCAL=ALL REBOOT=ReallySuppress /l*v C:\offline_test\vmw_msi.log`""
  Write-Host "installer exit $($p.ExitCode)"; Result 'vmware-install' ($p.ExitCode -in 0, 3010) "exit=$($p.ExitCode)"
  Copy-Item C:\offline_test\vmw_msi.log $Res -ErrorAction SilentlyContinue
  Next 2 -Reboot
}

if ($Stage -eq 44) { Next 45 }
if ($Stage -in 2, 46) {
  Say 'VMware checks'
  $scr = Join-Path $Lib '10_INSTALLATION_SCRIPTS\ubuntu_vmware\create_vmware_vm.ps1'
  & $scr -CheckOnly; Result 'vmware-checkonly' ($LASTEXITCODE -eq 0 -or $null -eq $LASTEXITCODE)
  $vmw = @("$env:ProgramFiles\VMware\VMware Workstation", "${env:ProgramFiles(x86)}\VMware\VMware Workstation") | Where-Object { Test-Path "$_\vmrun.exe" } | Select-Object -First 1
  $vmrun = "$vmw\vmrun.exe"; $vdm = "$vmw\vmware-vdiskmanager.exe"
  Get-Service -DisplayName 'VMware*' -ErrorAction SilentlyContinue | Format-Table DisplayName, Status

  Say 'VM from the local ISO, using the script and template'
  Add-Content -Path (Join-Path $Res 'results.txt') -Value "--- VMware stage $Stage ---"
  $d = 'C:\VMs\ubuntu-from-iso'; if (Test-Path $d) { Remove-Item -Recurse -Force $d }
  & $scr -Kind server -VmDir $d -DiskGB 30; $vmx = "$d\ubuntu-from-iso.vmx"; Result 'vm-created-from-template' (Test-Path $vmx)
  (Get-Content $vmx) -replace 'memsize = ".*"', 'memsize = "2048"' -replace 'virtualHW.version = ".*"', 'virtualHW.version = "21"' | Set-Content -Encoding ascii $vmx
  Add-Content -Encoding ascii $vmx 'msg.autoAnswer = "TRUE"'
  $o = & $vmrun -T ws start $vmx nogui 2>&1; Write-Host "start: $o rc=$LASTEXITCODE"; $started = ($LASTEXITCODE -eq 0)
  Result 'vm-iso-poweron' $started "$o"
  if ($started) { Start-Sleep 240; & $vmrun -T ws list; & $vmrun -T ws stop $vmx hard }
  if (Test-Path "$d\vmware.log") { Copy-Item "$d\vmware.log" "$Res\vmware_iso_vm.log"; Select-String -Path "$d\vmware.log" -Pattern 'Monitor Mode|hypervisor|cdrom|sata0:1|Boot|BIOS|EFI:' | Select-Object -First 30 | ForEach-Object { $_.Line } }

  Say 'Prebuilt Ubuntu in VMware: tools, shared folder, snapshot'
  $d = 'C:\VMs\prebuilt'; if (Test-Path $d) { Remove-Item -Recurse -Force $d }; New-Item -ItemType Directory -Force -Path $d, 'C:\VMs\shared' | Out-Null
  'from-host' | Set-Content C:\VMs\shared\from_host.txt
  & $vdm -r (Join-Path $payload 'prebuilt\ubuntu-server.vmdk') -t 0 "$d\prebuilt.vmdk"; Result 'vmdk-convert' ($LASTEXITCODE -eq 0)
  $vmx = "$d\prebuilt.vmx"
  (Get-Content (Join-Path $Lib '03_VMWARE\vm_templates\ubuntu-2404-server.vmx.template')) -replace '@NAME@', 'prebuilt' -replace '@ISO@', 'none' -replace 'memsize = ".*"', 'memsize = "2048"' -replace 'sata0:1.startConnected = "TRUE"', 'sata0:1.startConnected = "FALSE"' -replace 'sata0:1.present = "TRUE"', 'sata0:1.present = "FALSE"' | Set-Content -Encoding ascii $vmx
  Add-Content -Encoding ascii $vmx 'msg.autoAnswer = "TRUE"'
  $o = & $vmrun -T ws start $vmx nogui 2>&1; Write-Host "start: $o"; $ok = ($LASTEXITCODE -eq 0); Result 'vm-prebuilt-poweron' $ok "$o"
  if ($ok) {
    $tools = ''; foreach ($i in 1..60) { Start-Sleep 30; $tools = (& $vmrun -T ws checkToolsState $vmx 2>&1) -join ' '; Write-Host "t=$($i*30)s tools=$tools"; if ($tools -match 'running') { break } }
    Result 'open-vm-tools-running-in-vmware' ($tools -match 'running') $tools
    Copy-Item "$d\vmware.log" "$Res\vmware_prebuilt_vm_after_wait.log" -ErrorAction SilentlyContinue
    if ($tools -notmatch 'running') { Write-Host 'tools not running: skipping guest steps'; & $vmrun -T ws stop $vmx hard; Next 5 }
    $g = @('-T', 'ws', '-gu', 'tester', '-gp', 'OfflineTest1!')
    function InGuest($cmd) { & $vmrun @g runProgramInGuest $vmx /bin/bash -c $cmd 2>&1; $script:grc = $LASTEXITCODE }
    InGuest 'systemd-detect-virt > /tmp/virt.txt; systemctl is-active open-vm-tools >> /tmp/virt.txt; vmware-toolbox-cmd -v >> /tmp/virt.txt; gcc --version | head -1 >> /tmp/virt.txt; uname -r >> /tmp/virt.txt'; Result 'run-program-in-guest' ($grc -eq 0) "rc=$grc"
    & $vmrun @g copyFileFromGuestToHost $vmx /tmp/virt.txt "$Res\vmware_guest_info.txt"; if (Test-Path "$Res\vmware_guest_info.txt") { Get-Content "$Res\vmware_guest_info.txt"; Result 'guest-is-vmware' ((Get-Content "$Res\vmware_guest_info.txt") -contains 'vmware') }
    & $vmrun -T ws enableSharedFolders $vmx; & $vmrun -T ws addSharedFolder $vmx shared C:\VMs\shared; Start-Sleep 20
    InGuest 'cat /mnt/hgfs/shared/from_host.txt > /tmp/hgfs.txt 2>&1; ls -la /mnt/hgfs/ >> /tmp/hgfs.txt 2>&1; echo OfflineTest1! | sudo -S sh -c "echo from-guest > /mnt/hgfs/shared/from_guest.txt" 2>>/tmp/hgfs.txt'
    & $vmrun @g copyFileFromGuestToHost $vmx /tmp/hgfs.txt "$Res\vmware_hgfs.txt"; if (Test-Path "$Res\vmware_hgfs.txt") { Get-Content "$Res\vmware_hgfs.txt" }
    Result 'shared-folder-host-to-guest' ((Test-Path "$Res\vmware_hgfs.txt") -and (Select-String -Path "$Res\vmware_hgfs.txt" -Pattern 'from-host' -Quiet))
    Result 'shared-folder-guest-to-host' (Test-Path C:\VMs\shared\from_guest.txt)
    & $vmrun -T ws snapshot $vmx base-clean; Result 'snapshot' ($LASTEXITCODE -eq 0)
    & $vmrun -T ws listSnapshots $vmx
    & $vmrun -T ws revertToSnapshot $vmx base-clean; Result 'snapshot-revert' ($LASTEXITCODE -eq 0)
    & $vmrun -T ws stop $vmx hard
  }
  if (Test-Path "$d\vmware.log") { Copy-Item "$d\vmware.log" "$Res\vmware_prebuilt_vm.log" }
  if ($Stage -eq 2) { Next 3 } else { Next 5 }
}

if ($Stage -eq 3) {
  Say 'WSL: enable Windows features'
  & (Join-Path $Lib '10_INSTALLATION_SCRIPTS\ubuntu_wsl\wsl_offline_install.ps1'); $rc = $LASTEXITCODE; Result 'wsl-stage1-features' ($rc -in 0, 3010) "rc=$rc"
  Next 4 -Reboot
}

if ($Stage -eq 4) {
  Say 'WSL: install without the Store and import Ubuntu'
  & (Join-Path $Lib '10_INSTALLATION_SCRIPTS\ubuntu_wsl\wsl_offline_install.ps1') -DistroName Ubuntu-24.04 -InstallDir C:\WSL\Ubuntu-24.04 -User dev; $rc = $LASTEXITCODE; Result 'wsl-install-import-configure' ($rc -eq 0 -or $null -eq $rc) "rc=$rc"
  $wsl = "$env:ProgramFiles\WSL\wsl.exe"; if (-not (Test-Path $wsl)) { $wsl = 'wsl.exe' }
  & $wsl --version; & $wsl --status; & $wsl --list --verbose
  $v = ((& $wsl --list --verbose) -replace "`0", '' | Select-String 'Ubuntu-24.04' | Out-String); Result 'wsl-version-2' ($v -match '\s2\s*$') $v.Trim()
  $u = ((& $wsl -d Ubuntu-24.04 -- whoami) -replace "`0", '').Trim(); Result 'wsl-default-user' ($u -eq 'dev') "user=$u"
  $linuxLib = ((& $wsl -d Ubuntu-24.04 -u root -- wslpath -a ($Lib -replace '\\', '/')) -replace "`0", '').Trim(); Write-Host "library in WSL: $linuxLib"
  Next 41
}

$wsl = "$env:ProgramFiles\WSL\wsl.exe"; if (-not (Test-Path $wsl)) { $wsl = 'wsl.exe' }
if ($Stage -in 41, 42, 43) {
  $linuxLib = ((& $wsl -d Ubuntu-24.04 -u root -- wslpath -a ($Lib -replace '\\', '/')) -replace "`0", '').Trim()
  $winres = ((& $wsl -d Ubuntu-24.04 -u root -- wslpath -a ($Res -replace '\\', '/')) -replace "`0", '').Trim()
}
if ($Stage -eq 41) {
  Say 'WSL: full development environment from the local repository'
  & $wsl -d Ubuntu-24.04 -u root -- bash "$linuxLib/10_INSTALLATION_SCRIPTS/dependency_installation/install_dev_environment.sh" --profile fulldev 2>&1 | Tee-Object -FilePath "$Res\wsl_install.log" | Select-Object -Last 8
  Result 'wsl-fulldev-install' ($LASTEXITCODE -eq 0) "rc=$LASTEXITCODE"
  Next 42
}
if ($Stage -eq 42) {
  Remove-Item "$Res\wsl_verify.csv", "$Res\wsl_system.csv" -ErrorAction SilentlyContinue
  & $wsl -d Ubuntu-24.04 -u root -- bash "$linuxLib/13_TESTS/dev_environment/verify_dev_environment.sh" --report "$winres/wsl_verify.csv" 2>&1 | Tee-Object -FilePath "$Res\wsl_verify.log" | Select-Object -Last 15
  Result 'wsl-dev-verify' ($LASTEXITCODE -eq 0) "fails=$LASTEXITCODE"
  & $wsl -d Ubuntu-24.04 -u root -- bash "$linuxLib/13_TESTS/system_tests/verify_system_tools.sh" --report "$winres/wsl_system.csv" 2>&1 | Tee-Object -FilePath "$Res\wsl_system.log" | Select-Object -Last 8
  Result 'wsl-system-verify' ($LASTEXITCODE -eq 0) "fails=$LASTEXITCODE"
  & $wsl -d Ubuntu-24.04 -u root -- systemctl is-system-running 2>&1
  Next 43
}
if ($Stage -eq 43) {
  Say 'WSL: backup and restore'
  $s = Join-Path $Lib '10_INSTALLATION_SCRIPTS\ubuntu_wsl'
  if (-not (Test-Path C:\offline_test\backup.tar)) { & "$s\wsl_backup.ps1" -DistroName Ubuntu-24.04 -OutFile C:\offline_test\backup.tar }
  Result 'wsl-backup' (Test-Path C:\offline_test\backup.tar)
  $refused = $false; try { & "$s\wsl_backup.ps1" -DistroName Ubuntu-24.04 -OutFile C:\offline_test\backup.tar } catch { $refused = $true; Write-Host "refused: $_" }; Result 'wsl-backup-refuses-overwrite' $refused
  $have = ((& $wsl --list --quiet) -replace "`0", '') -contains 'Ubuntu-restored'
  if (-not $have) { & "$s\wsl_restore.ps1" -BackupFile C:\offline_test\backup.tar -DistroName Ubuntu-restored -InstallDir C:\WSL\restored }
  $r = ((& $wsl -d Ubuntu-restored -u root -- sh -c 'gcc --version | head -1') -replace "`0", '').Trim(); Result 'wsl-restore' ($r -match 'gcc') $r
  $refused = $false; try { & "$s\wsl_restore.ps1" -BackupFile C:\offline_test\backup.tar -DistroName Ubuntu-restored -InstallDir C:\WSL\restored2 } catch { $refused = $true; Write-Host "refused: $_" }; Result 'wsl-restore-refuses-existing' ($refused -and -not (Test-Path C:\WSL\restored2))
  & $wsl --shutdown
  Next 44
}

if ($Stage -eq 45) {
  Say 'VMware did not start with the WSL hypervisor on: turn the hypervisor off and retry'
  bcdedit /set hypervisorlaunchtype off
  Next 46 -Reboot
}

if ($Stage -eq 5) {
  Say 'all stages finished'; 'done' | Set-Content (Join-Path $Res 'ALL_DONE.txt')
  Unregister-ScheduledTask -TaskName OfflineTest -Confirm:$false -ErrorAction SilentlyContinue
  Stop-Transcript | Out-Null; Stop-Computer -Force
}
