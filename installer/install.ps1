$ErrorActionPreference = 'Stop'
$dest = Join-Path $env:LOCALAPPDATA 'ChuangyeWin'
New-Item -ItemType Directory -Force -Path $dest | Out-Null
Copy-Item -Force (Join-Path $PSScriptRoot 'open.ps1') (Join-Path $dest 'open.ps1')
$ps1 = Join-Path $dest 'open.ps1'
$cmd = 'powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "' + $ps1 + '" "%1"'
New-Item -Force -Path 'HKCU:\Software\Classes\chuangye\shell\open\command' | Out-Null
Set-ItemProperty 'HKCU:\Software\Classes\chuangye' '(default)' 'URL:ChuangyeWin'
New-ItemProperty 'HKCU:\Software\Classes\chuangye' 'URL Protocol' '' -Force | Out-Null
Set-ItemProperty 'HKCU:\Software\Classes\chuangye\shell\open\command' '(default)' $cmd
Write-Host '安装完成，请关闭此窗口'
Read-Host
