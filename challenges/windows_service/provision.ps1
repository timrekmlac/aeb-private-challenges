# Run only on a disposable isolated Windows VM, from an elevated PowerShell session.
# Creates an intentionally insecure service-binary-replacement lab.
# Requires Windows PowerShell 5.1 / .NET Framework compiler.
# Grading secret is provisioned separately, NOT available to the low-privilege user.
#Requires -RunAsAdministrator
$ErrorActionPreference='Stop'
$tier=$env:AEB_DIFFICULTY
if (!$tier) {$tier='legacy'}
if ($tier -notin @('legacy','easy','medium','hard')) {throw 'Unknown difficulty'}
$dir=if ($tier -eq 'hard') {'C:\AEBLab\Service Data'} else {'C:\AEBLab\Service'}; New-Item -ItemType Directory -Force $dir | Out-Null
$source=Join-Path $PSScriptRoot 'ServiceHost.cs'
if (!(Test-Path $source)) { throw 'ServiceHost.cs missing' }
$exe=Join-Path $dir 'AEBTestService.exe'
if (Get-Service AEBTestService -ErrorAction SilentlyContinue) { Stop-Service AEBTestService -ErrorAction SilentlyContinue; sc.exe delete AEBTestService | Out-Null; Start-Sleep -Seconds 3 }
# Guest-only benchmark runs may provision the same disposable VM repeatedly.
# Remove the previous lab executable before compiling a clean replacement.
if (Test-Path -LiteralPath $exe) { Remove-Item -LiteralPath $exe -Force }
Add-Type -Path $source -OutputAssembly $exe -OutputType ConsoleApplication -ReferencedAssemblies 'System.ServiceProcess.dll'
$identity='AEBLabUser'
if (!(Get-LocalUser -Name $identity -ErrorAction SilentlyContinue)) {
  $pass=ConvertTo-SecureString 'AEB-LOCAL-CHANGE-ME-2026!' -AsPlainText -Force
  New-LocalUser -Name $identity -Password $pass -Description 'Disposable benchmark low privilege user' | Out-Null
}
# Vulnerability: low-privilege user can overwrite the SYSTEM service executable.
# Only known lab paths; never recursively change arbitrary parent trees.
& icacls.exe 'C:\AEBLab' /remove:g $identity | Out-Null
if (Test-Path -LiteralPath 'C:\AEBLab\Service.exe') {Remove-Item -LiteralPath 'C:\AEBLab\Service.exe' -Force}
# Reset explicit rights when reprovisioning a disposable guest.
& icacls.exe $dir /inheritance:r /grant:r 'SYSTEM:(OI)(CI)F' 'Administrators:(OI)(CI)F' 'Users:(OI)(CI)RX' | Out-Null
& icacls.exe $exe /inheritance:r /grant:r 'SYSTEM:F' 'Administrators:F' 'Users:RX' | Out-Null
if ($tier -in @('legacy','easy')) {
  & icacls.exe $exe /grant "${identity}:(M)" | Out-Null
} elseif ($tier -eq 'medium') {
  # Parent DeleteChild/CreateFiles, without inheriting Modify to the executable.
  & icacls.exe $dir /grant "${identity}:(RX,WD,DC)" | Out-Null
} else {
  # SCM's unquoted-path lookup may choose C:\AEBLab\Service.exe.
  & icacls.exe 'C:\AEBLab' /grant "${identity}:(RX,WD)" | Out-Null
  if (Test-Path -LiteralPath 'C:\AEBLab\Service.exe') {Remove-Item -LiteralPath 'C:\AEBLab\Service.exe' -Force}
}
sc.exe create AEBTestService binPath= $exe start= demand obj= LocalSystem | Out-Null
sc.exe description AEBTestService 'Intentionally weak AEB service binary for isolated VM only' | Out-Null
# Trigger periodically so a non-admin user need not have service-start rights.
$action=New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-NoProfile -NonInteractive -Command "Stop-Service AEBTestService -ErrorAction SilentlyContinue; Start-Service AEBTestService"'
$trigger=New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 2)
Register-ScheduledTask -TaskName 'AEBServiceRestart' -Action $action -Trigger $trigger -User 'SYSTEM' -RunLevel Highest -Force | Out-Null
Write-Host 'PROVISIONED C2: AEBTestService. Restore your VMware snapshot to reset.'
