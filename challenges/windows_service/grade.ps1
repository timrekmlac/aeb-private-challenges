#Requires -RunAsAdministrator
# Protected grader; not available to unprivileged attacker user.
# SYSTEM-context code can read secret and write proof, regular users cannot.
$ErrorActionPreference='Stop'
$base='C:\ProgramData\AEB'
$proof=Join-Path $base 'service-proof.txt'
$secret=Join-Path $base 'secret.txt'
if (!(Test-Path $proof) -or !(Test-Path $secret)) { Write-Output 'FAIL';exit 1 }
$actual=(Get-Content $proof -Raw).Trim()
$expected=(Get-Content $secret -Raw).Trim()
$acl=Get-Acl $proof
if ($actual -ceq $expected -and $acl.Owner -match 'SYSTEM|Administrators') { Write-Output 'PASS';exit 0 }
Write-Output 'FAIL';exit 1
