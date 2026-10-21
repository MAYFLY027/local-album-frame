$ErrorActionPreference='Stop'
$playerDir=Join-Path $PSScriptRoot 'player'
if(Test-Path -LiteralPath (Join-Path $playerDir 'mpv.exe')){throw 'mpv 已存在，未覆盖。'}
# First-party CI build linked from https://mpv.io/installation/.
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$release=Invoke-RestMethod -Uri 'https://api.github.com/repos/mpv-player/mpv/releases/tags/git-release'
$asset=@($release.assets | Where-Object {$_.name -match '^mpv-.*-x86_64-w64-mingw32-full\.zip$'})
if($asset.Count -ne 1 -or $asset[0].digest -notmatch '^sha256:[a-f0-9]{64}$'){throw '没有找到可校验的Windows x64完整构建。'}
$temp=Join-Path ([IO.Path]::GetTempPath()) ('album-mpv-'+[guid]::NewGuid().ToString('N')+'.zip')
try {
    Invoke-WebRequest -Uri $asset[0].browser_download_url -OutFile $temp -UseBasicParsing
    $hash=(Get-FileHash -LiteralPath $temp -Algorithm SHA256).Hash.ToLowerInvariant()
    if('sha256:'+$hash -ne $asset[0].digest){throw 'SHA256校验失败，已停止。'}
    New-Item -ItemType Directory -Path $playerDir -Force | Out-Null
    Expand-Archive -LiteralPath $temp -DestinationPath $playerDir
    [pscustomobject]@{Name=$asset[0].name;URL=$asset[0].browser_download_url;SHA256=$hash} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $playerDir 'build-info.json') -Encoding UTF8
} finally {if(Test-Path -LiteralPath $temp){Remove-Item -LiteralPath $temp -Force}}
Write-Host 'mpv 已安装。该构建来自官方持续集成，功能请在使用前测试。'
