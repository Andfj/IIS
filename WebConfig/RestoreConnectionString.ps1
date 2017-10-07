#HOW TO USE
#1 - define list of servers where we should run the script and put these values in the invoke-command below
#2 - specify envinronment ('prod' or 'stg') where to run the script and after that - run the scripts.
# Log will be created in the folder where script file is located.
#Exapmles how to run script: 
#RestoreConfig.ps1 prod 
#RestoreConfig.ps1 stg


#argument
$envinronment=$args[0]

if (!$envinronment)
{
    Write-Warning "Please define a variable on which envinronment (prod or stg) run the script"
    exit
}
elseif (($envinronment -ne 'prod') -and ( $envinronment -ne 'stg' ))
{
    Write-Warning "Envinronment can be prod  or stg only"
    exit
}

$file_to_log = "$PSScriptRoot\restore-backup-$(Get-Date  -Format 'yyyy-MM-dd-HHmmss').txt"

$command = {

#searching web.config and config.json
Write-Output "web.config and files below for $using:envinronment envinronment: `n"

if ($using:envinronment -eq 'prod') 
{
    $filesWebConfig = Get-ChildItem -Path 'C:\WebSites\*\*' -Directory | where { $_.FullName -notmatch "\w*(?i)(preview|stg)$" } | Get-ChildItem -filter 'web*.config'  -Recurse  -File | Where { $_.Name -match "web\d{12}\.config" }
}

if ($using:envinronment -eq 'stg') 
{
    $filesWebConfig = Get-ChildItem -Path 'C:\WebSites\*\*' -Directory | where { $_.FullName -match "\w*(?i)(preview|stg)$" } | Get-ChildItem -filter 'web*.config'  -Recurse  -File | Where { $_.Name -match "web\d{12}\.config" }
}


$filesWebConfig.fullname | Sort-Object -Descending 

#getting unique folders with backup files
$foldersToBackup = @()

foreach ($fileWebConfig in $filesWebConfig)
{
    $foldersToBackup += (Get-ChildItem -Path $fileWebConfig.fullname).DirectoryName
}

$foldersToBackup = $foldersToBackup | Select-Object -Unique

#restore latest backup file in each folder instead of original file
foreach($folderToBackup in $foldersToBackup)
{
    Write-Output "`nTrying to remove $($folderToBackup)\web.config..."
    try
    {
        Remove-Item -Path "$($folderToBackup)\web.config" -Force -ErrorAction Stop
        Write-Output "File $($folderToBackup)\web.config was removed"
    }
    catch 
    {
        Write-Output "Cannot remove $($folderToBackup)\web.config"
    }


    $filesWebConfigToRestore =  Get-ChildItem -Path $folderToBackup -filter 'web*.config' -File | Where { $_.Name -match "web\d{12}\.config" } 
    $fileWebConfigToRestore  = $filesWebConfigToRestore.fullname | Sort-Object -Descending | Select-Object -First 1

    try
    {
        Rename-Item -Path $fileWebConfigToRestore -NewName 'web.config' -Force -ErrorAction Stop
        Write-Output "$fileWebConfigToRestore was restored as web.config"

    }
    catch
    {
        Write-Output "Can not rename $fileWebConfigToRestore"
    }


}

}


Start-Transcript -Path $file_to_log -NoClobber

Invoke-Command -ComputerName "servername" -ScriptBlock $command

Stop-Transcript
