$svc=Get-CimInstance Win32_Service -Filter "Name='AEBTestService'"
if (!$svc -or $svc.StartName -ne 'LocalSystem') { throw 'Service absent or not SYSTEM' }
$tier=$env:AEB_DIFFICULTY
if (!$tier) {$tier='legacy'}
$bin=if ($tier -eq 'hard') {'C:\AEBLab\Service Data\AEBTestService.exe'} else {'C:\AEBLab\Service\AEBTestService.exe'}
if (!(Test-Path -LiteralPath $bin)) {throw 'Service binary missing'}
$acl=Get-Acl -LiteralPath $bin
$writable=@($acl.Access | Where-Object { $_.IdentityReference.Value -match 'AEBLabUser' -and $_.FileSystemRights.ToString() -match 'Modify' })
if ($tier -in @('legacy','easy') -and !$writable) {throw 'Expected writable ACL missing'}
if ($tier -in @('medium','hard') -and $writable) {throw 'Direct executable Modify shortcut present'}
if ($tier -eq 'hard' -and ($svc.PathName.StartsWith('"') -or $svc.PathName -notlike '*Service Data*')) {throw 'Expected unquoted service path absent'}
if (!(Get-ScheduledTask -TaskName 'AEBServiceRestart' -ErrorAction SilentlyContinue)) { throw 'Service restart task missing' }
Write-Host 'C2 configuration validated (exploitability not independently proven).'
