param([Parameter(Mandatory)][string]$CoreDirectory,[Parameter(Mandatory)][string]$Destination)
$ErrorActionPreference='Stop'
$out=Join-Path $PSScriptRoot 'output'
& (Join-Path $PSScriptRoot 'Build.ps1')
$Destination=[IO.Path]::GetFullPath($Destination)
New-Item -Type Directory -Force -Path $Destination | Out-Null
$stage=Join-Path $Destination ('package-'+[guid]::NewGuid().ToString('N'))
New-Item -Type Directory -Path $stage | Out-Null
$files=@('onyx_vpn.exe','onyx_vpn.exe.config','Microsoft.Web.WebView2.Core.dll','Microsoft.Web.WebView2.WinForms.dll','WebView2Loader.dll','interface/index.html','interface/tailwind.css','interface/icon.png','assets/brand/onyx.ico','assets/brand/iii85iii-luxury.ico','assets/brand/iii85iii-luxury.png','assets/brand/infinity_loop.png','assets/fonts/Lato-Regular.ttf','assets/fonts/Lato-Bold.ttf','assets/fonts/Lato-Black.ttf','assets/fonts/OFL.txt','assets/fonts/Vazirmatn-Regular.ttf','assets/fonts/Vazirmatn-Bold.ttf','assets/fonts/Vazirmatn-OFL.txt')
foreach($file in $files){
    $target=Join-Path $stage $file
    New-Item -Type Directory -Force -Path (Split-Path $target) | Out-Null
    Copy-Item -LiteralPath (Join-Path $out $file) -Destination $target
}
New-Item -Type Directory -Path "$stage/core","$stage/licenses" | Out-Null
New-Item -Type Directory -Path "$stage/docs" | Out-Null
Copy-Item -LiteralPath (Join-Path (Split-Path $CoreDirectory) 'docs/guide.html') -Destination "$stage/docs"
$manifest=Get-Content -LiteralPath "$CoreDirectory/manifest.json" -Raw | ConvertFrom-Json
foreach($name in @('onyx-core.exe','iii85iii-tun.exe','firefox-vpn-core.exe','firefox-vpn-tun.exe','iii85iii-core.exe','onyx-tun.exe')){
    $src=Join-Path $CoreDirectory $name
    if ((Get-FileHash -LiteralPath $src).Hash -ne $manifest.$name){throw "Engine checksum mismatch: $name"}
    Copy-Item -LiteralPath $src -Destination "$stage/core"
}
Copy-Item -LiteralPath "$CoreDirectory/manifest.json" -Destination "$stage/core"
foreach($name in @('GPL-3.0.txt','NOTICE.txt')){
    Copy-Item -LiteralPath "$PSScriptRoot/../licenses/$name" -Destination "$stage/licenses"
}
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip=Join-Path $Destination 'ONYX-Windows-x64.zip'
[IO.Compression.ZipFile]::CreateFromDirectory($stage,$zip)
$compiler=Join-Path $env:WINDIR 'Microsoft.NET/Framework64/v4.0.30319/csc.exe'
$setup=(Resolve-Path (Join-Path $PSScriptRoot 'Setup.cs')).Path
$appManifest=(Resolve-Path (Join-Path $PSScriptRoot 'app.manifest')).Path
$icon=(Resolve-Path (Join-Path $out 'assets/brand/onyx.ico')).Path
$installer=Join-Path $Destination 'ONYX-VPN-Setup.exe'
& $compiler /nologo /target:winexe /platform:x64 /optimize+ /r:System.IO.Compression.dll /r:System.IO.Compression.FileSystem.dll /r:Microsoft.CSharp.dll /r:System.Windows.Forms.dll "/win32manifest:$appManifest" "/win32icon:$icon" "/resource:$zip,payload.zip" "/out:$installer" $setup
if($LASTEXITCODE){throw 'Could not compile ONYX Setup.'}
