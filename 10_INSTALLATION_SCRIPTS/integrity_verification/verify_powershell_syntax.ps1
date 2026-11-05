<# Parse every .ps1 in this library with the real PowerShell parser, without running any of them. Run on Windows. #>
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path; $bad = 0
Get-ChildItem -Path $root -Recurse -Filter *.ps1 | ForEach-Object {
  $e = $null; $t = $null
  [void][System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$t, [ref]$e)
  if ($e.Count) { $bad++; Write-Output "FAIL $($_.Name)"; $e | ForEach-Object { Write-Output "  L$($_.Extent.StartLineNumber): $($_.Message)" } } else { Write-Output "OK   $($_.Name)" }
}
exit $bad
