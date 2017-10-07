#HOW TO USE
#1 - define list of servers where we should run the script and put these values in the invoke-command below and after that - run the scripts.
#2 - specify envinronment ('prod' or 'stg') where to run the script and after that - run the scripts.
# Log will be created in the folder where script file is located.
#Exapmles how to run script: 
#UpdateConnString prod 
#UpdateConnString stg

#argument
$envinronment=$args[0]

if (!$envinronment)
{
    Write-Warning "Please define a variable on which envinronment (prod or test) run the script"
    exit
}
elseif (($envinronment -ne 'prod') -and ( $envinronment -ne 'stg' ))
{
    Write-Warning "Envinronment can be prod  or test only"
    exit
}

##################################################################################################################################################

$file_to_log = "$PSScriptRoot\update-app-conf-$(Get-Date  -Format 'yyyy-MM-dd-HHmmss').txt"

$command = {

#searching web.config and config.json
Write-Output "==============START WORKING IN $env:COMPUTERNAME =============="
Write-Output "web.config and config.json files below: `n"

if ($using:envinronment -eq 'prod') 
{
    $filesWebConfig = Get-ChildItem -Path 'C:\WebSites\*\*' -Directory | where { $_.FullName -notmatch "\w*(?i)(stg|preview)$" } | Get-ChildItem -filter 'web.config'  -Recurse  -File 
}

if ($using:envinronment -eq 'stg') 
{
    $filesWebConfig = Get-ChildItem -Path 'C:\WebSites\*\*' -Directory | where { $_.FullName -match "\w*(?i)(stg|preview)$" } | Get-ChildItem -filter 'web.config'  -Recurse  -File 
}

$filesConfigJson = Get-ChildItem -Path 'C:\WebSites\' -filter 'config.json' -Recurse  -File

$filesWebConfig.fullname  | Sort-Object


Write-Output "`nFiles with connectionString value: `n"

foreach($fileWebConfig in $filesWebConfig)
{
    #searching connectionString in the file
    [xml]$fileContent = Get-Content -Path $fileWebConfig.fullname
    $connString = $fileContent.configuration.appSettings.add | where { $_.key -eq 'ConnectionString' } 
    $flagConnString = 0

    if ($connString)
    {
        Write-Output "`n`nFile name $($fileWebConfig.fullname)"    
        Write-Output "Connection string: $($connString.value)"

        #replace data source in Connection String
        $regexTestDB = "Data\sSource\s*=TestDB;"
        $regexMinPoolSize = "Min\sPool\sSize\s*=10"
        $regexMultiSubnetFail = ";MultiSubnetFailover=True"

        if ($connString.value -match $regexTestDB) { $connString.value = $connString.value -replace $regexTestDB, 'Data Source=TestDBNew;'; $flagConnString = 1 }
        if ($connString.value -match $regexMinPoolSize) { $connString.value = $connString.value -replace $regexMinPoolSize, 'Min Pool Size=0'; $flagConnString = 1  }
        
        #add new property in connection string
        if ($connString.value -notmatch $regexMultiSubnetFail) { $connString.value = -join($connString.value, ';MultiSubnetFailover=True');  $flagConnString = 1  }
        

        #backup current config files before saving new changes
        if ($flagConnString)
        {
            $folderToBackup = (Get-ChildItem -Path $fileWebConfig.fullname).DirectoryName
            $FileName = (Get-ChildItem -Path $fileWebConfig.fullname).BaseName
            $extFileName = (Get-ChildItem -Path $fileWebConfig.fullname).Extension
            $backupFileName = "$folderToBackup\$FileName$(Get-Date -Format yyyyMMddHHmm)$extFileName"

            try 
            {
                Write-Output "Trying to create backup of $($fileWebConfig.fullname) to $backupFileName"
                Copy-Item $fileWebConfig.fullname -Destination $backupFileName -Force -ErrorAction Stop
                $fileContent.Save($fileWebConfig.fullname)
                Write-Output "Backup of file $($fileWebConfig.fullname) was succeed"
            }
            catch
            {
                Write-Output "Can not create backup of file: $($fileWebConfig.fullname)"
            }
        }
        else
        {
            Write-Output "Connection string have value: $($connString.value) and don't match our conditions"
        }

    }
}

Write-Output "==============STOP WORKING IN $env:COMPUTERNAME =============="

}

Start-Transcript -Path $file_to_log -NoClobber

Invoke-Command -ComputerName "servername" -ScriptBlock $command

Stop-Transcript
