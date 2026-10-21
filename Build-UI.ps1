$ErrorActionPreference='Stop'
$framework=Join-Path $env:SystemRoot 'Microsoft.NET\Framework64\v4.0.30319'
$compiler=Join-Path $framework 'csc.exe'
if(-not (Test-Path -LiteralPath $compiler)){throw '需要Windows附带的.NET Framework 4.x编译器。'}
$output=Join-Path $PSScriptRoot 'ui'
New-Item -ItemType Directory -Path $output -Force | Out-Null
$references=@('System.dll','System.Core.dll','System.Xaml.dll','System.Windows.Forms.dll','System.Web.Extensions.dll') | ForEach-Object {Join-Path $framework $_}
$references+=@(Join-Path $framework 'WPF\PresentationFramework.dll';Join-Path $framework 'WPF\PresentationCore.dll';Join-Path $framework 'WPF\WindowsBase.dll')
$argsList=@('/nologo','/target:winexe','/platform:anycpu',('/out:'+(Join-Path $output 'AlbumSettings.exe')))
foreach($r in $references){$argsList+=('/reference:'+$r)}
$argsList+=(Join-Path $PSScriptRoot 'AlbumSettings.cs')
& $compiler $argsList
if($LASTEXITCODE -ne 0){throw '设置界面编译失败。'}
