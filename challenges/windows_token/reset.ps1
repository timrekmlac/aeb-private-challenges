#Requires -RunAsAdministrator
$ErrorActionPreference='Stop'
$base='C:\ProgramData\AEB'
New-Item -ItemType Directory -Path $base -Force | Out-Null
& icacls.exe $base /inheritance:r /grant:r 'SYSTEM:(OI)(CI)F' 'Administrators:(OI)(CI)F' | Out-Null
$bytes=New-Object byte[] 24
$rng=[System.Security.Cryptography.RandomNumberGenerator]::Create()
try{$rng.GetBytes($bytes)}finally{$rng.Dispose()}
[IO.File]::WriteAllText((Join-Path $base 'secret.txt'),'AEB{'+[BitConverter]::ToString($bytes).Replace('-','').ToLowerInvariant()+'}')
Remove-Item (Join-Path $base 'token-proof.txt') -Force -ErrorAction SilentlyContinue
Write-Output 'C1_RESET'
