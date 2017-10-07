#HOW TO USE
#1 - define list of servers where we should run the script and put these values in the invoke-command below and after that - run the scripts.
# Log will be created in the folder where script file is located.


$file_to_log = "$PSScriptRoot\add-aliases-$(Get-Date  -Format 'yyyy-m-dd-HHMMss').txt"

$command = {
    $checkAliases = Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\MSSQLServer\Client' | Where-Object { ($_.PSChildName -eq 'ConnectTo') -and ($_.ValueCount -ge 2 )}

    $registryValues = @('HKLM:\SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo', 'SQLListener1', 'DBMSSOCN,srv-sql01.domain.local,1433', 'String'),
                      @('HKLM:\SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo', 'SQLListener2', 'DBMSSOCN,srv-sql01.domain.local,1433', 'String'),
                      @('HKLM:\SOFTWARE\Wow6432Node\Microsoft\MSSQLServer\Client\ConnectTo', 'SQLListener1', 'DBMSSOCN,srv-sql01.domain.local,1433', 'String'),
                      @('HKLM:\SOFTWARE\Wow6432Node\Microsoft\MSSQLServer\Client\ConnectTo', 'SQLListener2', 'DBMSSOCN,srv-sql01.domain.local,1433', 'String')


    if ($checkAliases)
    {
        #Write-Output "Server have aliases"
        for($i=0; $i -lt $registryValues.Length; $i++)
        {
            New-ItemProperty -Path $registryValues[$i][0] -Name $registryValues[$i][1] -Value $registryValues[$i][2] -PropertyType $registryValues[$i][3] -Force | Out-Null
            Write-Host "$(Get-Date  -Format 'yyyy-m-dd HH-MM-ss'): added to $env:COMPUTERNAME alias $($registryValues[$i][1])"
        }
    

    }
    else
    {
        Write-Output "No aliases at all"
    }


}

$servers= Get-ADComputer -Filter {name -like "*"} -SearchBase "OU=Servers,DC=domain,DC=local"

Start-Transcript -Path $file_to_log -NoClobber

Invoke-Command -ComputerName $servers.name -ScriptBlock $command #-ErrorAction SilentlyContinue

Stop-Transcript
