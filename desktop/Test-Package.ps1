param([Parameter(Mandatory)][string]$PackageDirectory)
$ErrorActionPreference='Stop'
$root=Join-Path ([IO.Path]::GetTempPath()) ('onyx-setup-test-'+[guid]::NewGuid().ToString('N'))
$expectedZip=Join-Path $PackageDirectory 'ONYX-Windows-x64.zip'
$setup=[Reflection.Assembly]::LoadFile((Resolve-Path (Join-Path $PackageDirectory 'ONYX-VPN-Setup.exe')).Path)
$methods=[Reflection.BindingFlags]'Static,NonPublic'
$type=$setup.GetType('Setup',$true)
$payload=$setup.GetManifestResourceStream('payload.zip')
try{$digest=[BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash($payload)).Replace('-','')
    if($digest -ne (Get-FileHash $expectedZip).Hash){throw 'Installer and portable packages differ'}
}finally{$payload.Dispose()}
$dir=Join-Path $root 'Versions'
$exe=$type.GetMethod('Install',$methods).Invoke($null,[string[]]@($dir))
if($exe -ne $type.GetMethod('Install',$methods).Invoke($null,[string[]]@($dir))){throw 'Repeat installation is not stable'}
if([Reflection.AssemblyName]::GetAssemblyName($exe).Version.ToString(3) -ne '1.1.27'){throw 'Wrong installed version'}
$links=Join-Path $root 'Desktop'
New-Item -Type Directory -Path $links | Out-Null
$shell=New-Object -ComObject WScript.Shell
$legacy=$shell.CreateShortcut((Join-Path $links '85.lnk'))
$legacy.TargetPath=Join-Path $env:LOCALAPPDATA 'Programs\III85III VPN\III85III VPN.exe'
$legacy.Save()
$type.GetMethod('Link',$methods).Invoke($null,[string[]]@($links,$exe))
foreach($name in @('ONYX VPN.lnk','85.lnk')){
    if($shell.CreateShortcut((Join-Path $links $name)).TargetPath -ne $exe){throw "Wrong shortcut: $name"}
}
'Setup and portable payloads match; clean install, reinstall and legacy shortcut migration passed.'
