param([ValidateSet('Default','Sequential','Random')][string]$Order='Default', [switch]$ImagesOnly, [string]$DiagnosticLog)
$ErrorActionPreference='Stop'
$mutex=$null
$ownsMutex=$false
try {
    $rootDir=$PSScriptRoot
    $settingsFile=Join-Path $rootDir 'settings.json'
    if(-not (Test-Path -LiteralPath $settingsFile)){throw '请复制 settings.example.json 为 settings.json，填写相册目录。'}
    $settings=Get-Content -LiteralPath $settingsFile -Raw -Encoding UTF8 | ConvertFrom-Json
    if(-not (Test-Path -LiteralPath $settings.MediaRoot -PathType Container)){throw '相册目录不可访问。请先打开 CloudDrive 并确认挂载成功。'}
    $seconds=[double]$settings.ImageSeconds
    if($seconds -lt 1 -or $seconds -gt 86400){throw '图片停留时间应为1至86400秒。'}
    $player=Join-Path $rootDir 'player\mpv.exe'
    if(-not (Test-Path -LiteralPath $player)){throw '未找到 mpv。请先运行 Install-Mpv.ps1，或将可信 mpv Windows 版本放入 player 目录。'}
    # One player for this installation. Restart through a local named pipe only.
    $sha=[Security.Cryptography.SHA256]::Create()
    $key=([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($rootDir.ToLowerInvariant())))).Replace('-','').Substring(0,16)
    $sha.Dispose()
    $pipeName='local-album-frame-'+$key
    $mutex=New-Object Threading.Mutex($false,('Local\AlbumFrame-'+$key))
    try {$ownsMutex=$mutex.WaitOne(0)} catch [Threading.AbandonedMutexException] {$ownsMutex=$true}
    if(-not $ownsMutex){
        $pipe=New-Object IO.Pipes.NamedPipeClientStream('.', $pipeName, [IO.Pipes.PipeDirection]::Out)
        try {
            $pipe.Connect(2000)
            $writer=New-Object IO.StreamWriter($pipe)
            $writer.AutoFlush=$true
            $writer.WriteLine('{"command":["quit"]}')
            $writer.Dispose()
        } catch { } finally {$pipe.Dispose()}
        try {$ownsMutex=$mutex.WaitOne(30000)} catch [Threading.AbandonedMutexException] {$ownsMutex=$true}
        if(-not $ownsMutex){throw '相册正在启动或关闭，请稍后再试。没有重复打开第二个播放器。'}
    }
    $extensions=@('.jpg','.jpeg','.png','.webp','.bmp','.gif','.tif','.tiff','.avif','.jxl')
    if($settings.IncludeVideos -and -not $ImagesOnly){$extensions+=@('.mp4','.mkv','.mov','.m4v','.webm','.avi','.wmv','.mpg','.mpeg','.ts')}
    # Enumerate file names only. No thumbnail generation, video probing, or media upload.
    $pending=New-Object 'System.Collections.Generic.Stack[string]'
    $pending.Push([IO.Path]::GetFullPath($settings.MediaRoot))
    $paths=New-Object 'System.Collections.Generic.List[string]'
    while($pending.Count -gt 0){
        $dir=$pending.Pop()
        foreach($item in Get-ChildItem -LiteralPath $dir -Force -ErrorAction Stop){
            if($item.PSIsContainer){
                if(-not ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)){$pending.Push($item.FullName)}
            } elseif($item.Extension.ToLowerInvariant() -in $extensions){$paths.Add($item.FullName)}
        }
    }
    if($paths.Count -eq 0){throw '相册目录内没有支持的图片或视频。'}
    $runtime=Join-Path $rootDir 'runtime'
    New-Item -ItemType Directory -Path $runtime -Force | Out-Null
    $playlist=Join-Path $runtime ('playlist-'+[guid]::NewGuid().ToString('N')+'.m3u8')
    # UTF-8 without BOM, compatible with mpv and Chinese file names.
    [IO.File]::WriteAllLines($playlist, [string[]]@($paths | Sort-Object), (New-Object Text.UTF8Encoding($false)))
    $shuffle=[bool]$settings.Shuffle
    if($Order -eq 'Sequential'){$shuffle=$false}
    if($Order -eq 'Random'){$shuffle=$true}
    $argsList=@(('--config-dir="'+(Join-Path $rootDir 'portable_config')+'"'), ('--playlist="'+$playlist+'"'), ('--image-display-duration='+$seconds.ToString([Globalization.CultureInfo]::InvariantCulture)))
    $argsList+=('--mute='+$(if($settings.PlaySound){'no'}else{'yes'}))
    $argsList+=('--input-ipc-server=\\.\pipe\'+$pipeName)
    $argsList+='--idle=no'
    if($DiagnosticLog){$argsList+=('--log-file="'+$DiagnosticLog+'"')}
    if($shuffle){$argsList+='--shuffle'}
    $p=Start-Process -FilePath $player -ArgumentList $argsList -WorkingDirectory $rootDir -PassThru
    $p.WaitForExit()
    # Only this launch's generated file is removed; never touch source media.
    Remove-Item -LiteralPath $playlist -Force -ErrorAction SilentlyContinue
} catch {
    Add-Type -AssemblyName System.Windows.Forms
    [Windows.Forms.MessageBox]::Show($_.Exception.Message, '新版电子相册') | Out-Null
    exit 1
} finally {
    if($ownsMutex -and $mutex){$mutex.ReleaseMutex()}
    if($mutex){$mutex.Dispose()}
}
