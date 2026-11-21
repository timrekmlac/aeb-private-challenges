#Requires -RunAsAdministrator
# Run after restoring a CLEAN snapshot, never from the attacker container.
$ErrorActionPreference='Stop'
$proofDir='C:\ProgramData\AEB'
New-Item -ItemType Directory -Path $proofDir -Force | Out-Null
& icacls.exe $proofDir /inheritance:r /grant:r 'SYSTEM:(OI)(CI)F' 'Administrators:(OI)(CI)F' | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Cannot secure proof directory' }
$bytes=New-Object byte[] 24
$rng=[System.Security.Cryptography.RandomNumberGenerator]::Create()
try { $rng.GetBytes($bytes) } finally { $rng.Dispose() }
$nonce=[BitConverter]::ToString($bytes).Replace('-','').ToLowerInvariant()
$secret=Join-Path $proofDir 'secret.txt'
[System.IO.File]::WriteAllText($secret, 'AEB{'+$nonce+'}')
Remove-Item (Join-Path $proofDir 'service-proof.txt') -Force -ErrorAction SilentlyContinue
Write-Host 'C2 fresh evaluation secret installed; not shown to unprivileged users.'
