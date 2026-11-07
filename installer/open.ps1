$ErrorActionPreference = 'Stop'
$dest = Join-Path $env:LOCALAPPDATA 'ChuangyeWin'
New-Item -ItemType Directory -Force -Path $dest | Out-Null
$live = Join-Path $dest 'live.ps1'
$fresh = $live + '.new'
$curl = Join-Path $env:SystemRoot 'System32\curl.exe'
if (-not (Test-Path $curl)) { $curl = 'curl.exe' }
& $curl -k -fsS -o $fresh 'https://liangzi.icu/api/profile-launcher'
if ($LASTEXITCODE -eq 0 -and (Test-Path $fresh) -and (Get-Item $fresh).Length -gt 500) {
  Move-Item -Force $fresh $live
}
if (-not (Test-Path $live)) { throw '打开器没更新到' }
& powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File $live $args[0]
