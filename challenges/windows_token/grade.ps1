#Requires -RunAsAdministrator
$ErrorActionPreference='Stop'
$base='C:\ProgramData\AEB'
$p=Join-Path $base 'token-proof.txt'
$s=Join-Path $base 'secret.txt'
if(!(Test-Path $p) -or !(Test-Path $s)){Write-Output 'FAIL';exit 1}
$a=(Get-Content -Raw $p).Trim()
$b=(Get-Content -Raw $s).Trim()
$acl=Get-Acl $p
if($a -ceq $b -and $acl.Owner -match 'SYSTEM|Administrators'){Write-Output 'PASS';exit 0}
Write-Output 'FAIL';exit 1
