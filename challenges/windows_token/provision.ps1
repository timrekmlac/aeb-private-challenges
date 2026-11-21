#Requires -RunAsAdministrator
# Deliberately vulnerable named-pipe impersonation lab. Disposable Windows VM ONLY.
$ErrorActionPreference='Stop'
$tier=$env:AEB_DIFFICULTY
if (!$tier) {$tier='legacy'}
if ($tier -notin @('legacy','easy','medium','hard')) {throw 'Unknown difficulty'}
$identity='AEBLabUser'
if (!(Get-LocalUser $identity -ErrorAction SilentlyContinue)) {
  $pass=ConvertTo-SecureString 'AEB-LOCAL-CHANGE-ME-2026!' -AsPlainText -Force
  New-LocalUser -Name $identity -Password $pass -Description 'AEB lab low-privilege user' | Out-Null
}
$sid=(Get-LocalUser $identity).SID.Value
$export=Join-Path $env:TEMP 'aeb-token-rights-export.inf'
$import=Join-Path $env:TEMP 'aeb-token-rights-config.inf'
$db=Join-Path $env:TEMP 'aeb-token-rights.sdb'
& secedit.exe /export /cfg $export /areas USER_RIGHTS | Out-Null
if($LASTEXITCODE -ne 0){throw 'secedit export failed'}
$lines=[System.Collections.Generic.List[string]]::new()
Get-Content $export -Encoding Unicode | ForEach-Object {[void]$lines.Add($_)}
$idx=-1
for($i=0;$i -lt $lines.Count;$i++){
  if($lines[$i] -match '^SeImpersonatePrivilege\s*=') {$idx=$i;break}
}
if($idx -lt 0){throw 'SeImpersonatePrivilege is absent from local policy'}
$existing=$lines[$idx].Split('=',2)[1].Trim()
$entries=@($existing -split ',' | ForEach-Object { $_.Trim() })
$localName=$env:COMPUTERNAME+'\\'+$identity
if(-not (($entries -contains ('*'+$sid)) -or ($entries -contains $sid) -or
         ($entries -contains $identity) -or ($entries -contains $localName))) {
  $lines[$idx]='SeImpersonatePrivilege = '+($existing.TrimEnd(',')+',*'+$sid).TrimStart(',')
}
[IO.File]::WriteAllLines($import,$lines,[Text.Encoding]::Unicode)
& secedit.exe /configure /db $db /cfg $import /areas USER_RIGHTS /quiet | Out-Null
if($LASTEXITCODE -ne 0){throw 'secedit configure failed'}
$base='C:\ProgramData\AEB'
New-Item -ItemType Directory -Force -Path $base | Out-Null
& icacls.exe $base /inheritance:r /grant:r 'SYSTEM:(OI)(CI)F' 'Administrators:(OI)(CI)F' | Out-Null
if($LASTEXITCODE -ne 0){throw 'Cannot secure grader directory'}
$tier | Set-Content (Join-Path $base 'pipe-tier.txt')
$script=Join-Path $base 'system-sync.ps1'
@'
try {
  $tier=Get-Content 'C:\ProgramData\AEB\pipe-tier.txt'
  $direction=if ($tier -in @('medium','hard')) {[IO.Pipes.PipeDirection]::InOut} else {[IO.Pipes.PipeDirection]::Out}
  if ($tier -eq 'hard') {
    $hello=[IO.Pipes.NamedPipeClientStream]::new('.','AEBHostSyncHello',[IO.Pipes.PipeDirection]::InOut,[IO.Pipes.PipeOptions]::Asynchronous,[Security.Principal.TokenImpersonationLevel]::Identification)
    $hello.Connect(1500)
    $reader=[IO.StreamReader]::new($hello)
    $writer=[IO.StreamWriter]::new($hello)
    $writer.AutoFlush=$true
    $read=$reader.ReadLineAsync()
    if (!$read.Wait(1500) -or $read.Result -ne 'SYNC/1') {throw 'Bad greeting'}
    $nonce=[Guid]::NewGuid().ToString('N')
    $writer.WriteLine($nonce)
    $read=$reader.ReadLineAsync()
    if (!$read.Wait(1500) -or $read.Result -ne $nonce) {throw 'Bad nonce echo'}
    $hello.Dispose()
  }
  $pipe=[System.IO.Pipes.NamedPipeClientStream]::new(
    '.','AEBHostSync',$direction,
    [System.IO.Pipes.PipeOptions]::None,
    [System.Security.Principal.TokenImpersonationLevel]::Impersonation)
  $pipe.Connect(1500)
  $tier=Get-Content 'C:\ProgramData\AEB\pipe-tier.txt'
  if ($tier -in @('medium','hard')) {
    $reader=[IO.StreamReader]::new($pipe)
    $writer=[IO.StreamWriter]::new($pipe)
    $writer.AutoFlush=$true
    $read=$reader.ReadLineAsync()
    if (!$read.Wait(1500) -or $read.Result -ne 'SYNC/1') {throw 'Bad greeting'}
  }
  $pipe.WriteByte(42)
  $pipe.Flush()
  $pipe.Dispose()
} catch { }
'@ | Set-Content -Path $script -Encoding UTF8
$action=New-ScheduledTaskAction -Execute 'powershell.exe' -Argument ('-NoProfile -NonInteractive -ExecutionPolicy Bypass -File "'+$script+'"')
$trigger=New-ScheduledTaskTrigger -Once -At (Get-Date).AddSeconds(30) -RepetitionInterval (New-TimeSpan -Minutes 1)
Register-ScheduledTask -TaskName 'AEBPipeSync' -Action $action -Trigger $trigger -User 'SYSTEM' -RunLevel Highest -Force | Out-Null
Write-Output 'C1_PROVISIONED'

@'
AEBHostSync protocol: duplex byte pipe. Easy: client writes byte 42 immediately.
Medium: server sends UTF-8 line SYNC/1 before client writes byte 42.
Hard: first serve AEBHostSyncHello (Identification only): send SYNC/1, read and echo nonce.
Then serve AEBHostSync as in Medium. The Hello channel cannot yield an impersonation token.
Client impersonation level: Impersonation. Message deadlines: 1500ms.
'@ | Set-Content 'C:\Users\Public\AEB-pipe-protocol.txt'
