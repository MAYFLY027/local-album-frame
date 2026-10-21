param([switch]$Desktop)
$ErrorActionPreference='Stop'
$shell=New-Object -ComObject WScript.Shell
$powershell=Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
if(-not (Test-Path -LiteralPath (Join-Path $PSScriptRoot 'ui\AlbumSettings.exe'))){& (Join-Path $PSScriptRoot 'Build-UI.ps1')}
foreach($entry in @(@{Name='新版相册-随机混播';Order='Random';Images=$false},@{Name='新版相册-顺序混播';Order='Sequential';Images=$false},@{Name='新版相册-仅图片';Order='Random';Images=$true})){
    $shortcut=$shell.CreateShortcut((Join-Path $PSScriptRoot ($entry.Name+'.lnk')))
    $shortcut.TargetPath=$powershell
    $shortcut.Arguments='-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "'+(Join-Path $PSScriptRoot 'Launch.ps1')+'" -Order '+$entry.Order
    if($entry.Images){$shortcut.Arguments+=' -ImagesOnly'}
    $shortcut.WorkingDirectory=$PSScriptRoot
    $shortcut.IconLocation=(Join-Path $PSScriptRoot 'player\mpv.exe')+',0'
    $shortcut.Save()
}
$shortcut=$shell.CreateShortcut((Join-Path $PSScriptRoot '新版相册-设置.lnk'))
$shortcut.TargetPath=Join-Path $PSScriptRoot 'ui\AlbumSettings.exe'
$shortcut.Arguments=''
$shortcut.WorkingDirectory=$PSScriptRoot
$shortcut.IconLocation=(Join-Path $PSScriptRoot 'player\mpv.exe')+',0'
$shortcut.Save()
if($Desktop){Copy-Item -LiteralPath (Join-Path $PSScriptRoot '新版相册-设置.lnk') -Destination (Join-Path ([Environment]::GetFolderPath('Desktop')) '新版电子相册（试用）.lnk')}
