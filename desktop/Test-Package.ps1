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
$installed=[Reflection.AssemblyName]::GetAssemblyName($exe).Version
if($installed.ToString() -ne [Diagnostics.FileVersionInfo]::GetVersionInfo($setup.Location).FileVersion){throw 'Wrong installed version'}
$app=[Reflection.Assembly]::LoadFile($exe)
$pick=$app.GetType('Onyx.Vpn.Engine',$true).GetMethod('AvailableProxyListener',$methods)
$busy=[Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback,0)
$busy.Start()
try {
    $dashboard=$busy.LocalEndpoint.Port
    $choice=$pick.Invoke($null,@($busy.LocalEndpoint,$dashboard))
    if($choice.Port -eq $dashboard -or !$choice.Address.Equals([Net.IPAddress]::Loopback)){throw 'Dashboard port collision'}
    $candidate=$pick.Invoke($null,@($busy.LocalEndpoint,$choice.Port))
    if($candidate.Port -in @($dashboard,$choice.Port)){throw 'Occupied proxy port selected'}
    $same=$pick.Invoke($null,@($candidate,$dashboard))
    if(!$same.Equals($candidate)){throw 'Available custom proxy port lost'}
}finally{$busy.Stop()}
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
