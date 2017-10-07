$command = {

Write-Output "START WORKING in $env:COMPUTERNAME"

#INITIAL DATA
$sitename = "MyWebApp"
$poolname = "MyWebApp"
$AppPoolUser = "DOMAIN\AppPoolUser"
$AppPoolPwd = "Passw0rd"
$physicalpath = 'C:\WebSites\MyWebApp'
#$bindings = @{protocol="http";bindingInformation="*:80:mywebapp.domain.local"}
$bindings = @( 
                @{protocol="http";bindingInformation="*:80:mywebapp.domain.local"},
                @{protocol="http";bindingInformation="*:80:mywebapp2.domain.local"}
             )


Import-Module WebAdministration

#FILE SYSTEM
New-Item  $physicalpath -ItemType directory -Force | Out-Null
Write-Output "folder was created"

#POOL
cd IIS:\AppPools\
$mypool= New-Item $poolname

$mypool.managedRuntimeVersion = "v4.0"
$mypool.managedPipelineMode = "Integrated"
$mypool.processModel.identityType = 3
$mypool.processModel.userName = $AppPoolUser
$mypool.processModel.password = $AppPoolPwd
$mypool.processModel.loadUserProfile = $true
$mypool.processModel.idleTimeout = '00:00:00'
$mypool.enable32BitAppOnWin64 = $true
$mypool | Set-Item

$mypool.Stop()
$mypool.Start()

Write-Output "Pool was created"

#SITE
New-Item IIS:\Sites\$sitename -Bindings $bindings -PhysicalPath $physicalpath -ApplicationPool $poolname | Out-Null

cd IIS:\Sites
$mysite = Get-Item $sitename
$mysite.logFile.logExtFileFlags = 'Date,Time,ClientIP,UserName,ServerIP,Method,UriStem,UriQuery,HttpStatus,Win32Status,BytesSent,BytesRecv,TimeTaken,ServerPort,UserAgent,Referer,HttpSubStatus'
$mysite | Set-Item

Write-Output "Site was created"

Write-Output "STOP WORKING in $env:COMPUTERNAME`n"

}

#Creating website on the following servers
$servers = Get-ADComputer -Filter {name -like "srv-iis-*"} -SearchBase "OU=Servers,DC=domain,DC=local"

foreach($server in $servers)
{
    Invoke-Command -ComputerName $server.name  -ScriptBlock $command
}
