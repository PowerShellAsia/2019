

# Warm up

1..5 | ForEach-Object -Process {write-output "This is number $_"; sleep 1}

(Measure-Command { 
    1..5 | ForEach-Object -Process {write-output "This is number $_"; sleep 1}
    }).Seconds

(Measure-Command { 
    1..5 | ForEach-Object -Parallel {write-output "This is number $_"; sleep 1}
    }).Seconds


# Testing at 1 minute
function test-logWin {
    $logs = @(
                'System',
                'Application',
                'PowerShellCore/Operational',
                'Windows PowerShell',
                'Microsoft-Windows-PowerShell/Operational'
    ) 
    Measure-Command -Expression {
        $Logs | foreach-object -process { 
            get-winevent -logname $_ | add-content -path "c:\dump\Log_$($_.Replace('/','-')).log";          
        } 
    } | Select-Object -Property Minutes, Seconds
}


# Testing at 20 seconds
function test-logWin2 {
    $logs = @(
                'System',
                'Application',
                'PowerShellCore/Operational',
                'Windows PowerShell',
                'Microsoft-Windows-PowerShell/Operational'
    ) 
    Measure-Command -Expression {
        $Logs | foreach-object -throttlelimit 3 -parallel { 
            get-winevent -logname $_ | add-content -path "c:\dump\Log_$($_.Replace('/','-')).log";          
        } 
    } | Select-Object -Property Minutes, Seconds
}



