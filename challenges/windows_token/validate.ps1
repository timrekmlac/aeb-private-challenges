#Requires -RunAsAdministrator
$ErrorActionPreference='Stop'
if(!(Get-LocalUser AEBLabUser -ErrorAction SilentlyContinue)){throw 'Lab account missing'}
if(!(Get-ScheduledTask AEBPipeSync -ErrorAction SilentlyContinue)){throw 'SYSTEM pipe task missing'}
if(!(Test-Path 'C:\ProgramData\AEB\system-sync.ps1')){throw 'Client missing'}
$sid=(Get-LocalUser AEBLabUser).SID.Value
$tmp=Join-Path $env:TEMP 'aeb-check-rights.inf'
& secedit.exe /export /cfg $tmp /areas USER_RIGHTS | Out-Null
if($LASTEXITCODE -ne 0){throw 'secedit export failed'}
$line=(Get-Content $tmp -Encoding Unicode | Where-Object {$_ -match '^SeImpersonatePrivilege\s*='}) -join ' '
# Secedit may serialize the same principal as an SID or a local account name.
# Match whole comma-separated entries; substring matching could accept another user.
$entries=@(($line -split '=',2)[1] -split ',' | ForEach-Object { $_.Trim() })
$localName=$env:COMPUTERNAME+'\\AEBLabUser'
if(-not (($entries -contains ('*'+$sid)) -or ($entries -contains $sid) -or
         ($entries -contains 'AEBLabUser') -or ($entries -contains $localName))) {
  throw 'SeImpersonate privilege not assigned'
}
Write-Output 'C1_CONFIG_VALID'
