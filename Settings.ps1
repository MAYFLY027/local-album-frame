param([switch]$FromPlayer)
$ErrorActionPreference='Stop'
$exe=Join-Path $PSScriptRoot 'ui\AlbumSettings.exe'
if(-not (Test-Path -LiteralPath $exe)){& (Join-Path $PSScriptRoot 'Build-UI.ps1')}
$p=Start-Process -FilePath $exe -Wait -PassThru
exit $p.ExitCode
