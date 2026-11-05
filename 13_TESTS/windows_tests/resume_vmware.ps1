<# Re-run only the VMware stage, for example after fixing a template. Keeps the first run's results. #>
$payload = (Get-PSDrive -PSProvider FileSystem | Where-Object { Test-Path ($_.Root + 'OFFLINE_TEST_PAYLOAD') } | Select-Object -First 1).Root
$Res = Join-Path $payload 'test_results'
if ((Test-Path "$Res\results.txt") -and -not (Test-Path "$Res\results_first_pass.txt")) { Copy-Item "$Res\results.txt" "$Res\results_first_pass.txt"; Add-Content "$Res\results.txt" '--- VMware stage re-run after the template fix ---' }
New-Item -ItemType File -Force -Path 'C:\offline_test\vmware_only' | Out-Null
Set-Content 'C:\offline_test\stage.txt' 2
& (Join-Path $payload 'Linux_Offline_Installation_Resource_Library\13_TESTS\windows_tests\run_windows_test.ps1')
