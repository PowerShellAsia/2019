param(
    [switch] $Processor,
    [switch] $PhysicalMemory,
    [switch] $VirtualMemory,
    [switch] $EthernetSend,
    [switch] $EthernetReceive,
    [switch] $DiskRead,
    [switch] $DiskWrite,
    $MaxStepsOnYAxis = 4,
    $MaxStepsOnXAxis = 20
)

Import-Module Graphical

Function Invoke-PerfMon {
    param(
        [switch] $Processor,
        [switch] $PhysicalMemory,
        [switch] $VirtualMemory,
        [switch] $EthernetSend,
        [switch] $EthernetReceive,
        [switch] $DiskRead,
        [switch] $DiskWrite,
        $MaxStepsOnYAxis = 4,
        $MaxStepsOnXAxis = 20
    )
        
    $ErrorActionPreference = 'Stop'
    [int[]]$CPU = @(0) * $MaxStepsOnXAxis
    [int[]]$RAM = @(0) * $MaxStepsOnXAxis
    [int[]]$PageFile = @(0) * $MaxStepsOnXAxis
    [int[]]$RecvPerSec = @(0) * $MaxStepsOnXAxis
    [int[]]$SentPerSec = @(0) * $MaxStepsOnXAxis
    [int[]]$DiskReadsPerSec = @(0) * $MaxStepsOnXAxis
    [int[]]$DiskWritesPerSec = @(0) * $MaxStepsOnXAxis
    $RecvPrev = 0
    $SentBytesPrev = 0
    $DiskReadBytesPrev = 0
    $DiskWriteBytesPrev = 0
        
        
    function round($n) {
        return $($n + (10 - $n % 10))
    }
        
    do {
        try { 
            $OS = Get-Ciminstance Win32_OperatingSystem
            $Performance = [ordered]@{
                "CPU"      = (Get-CimInstance win32_processor).LoadPercentage
                "RAM"      = (100 - ($OS.FreePhysicalMemory / $OS.TotalVisibleMemorySize) * 100)
                "Pagefile" = (100 - ($OS.FreeVirtualMemory / $OS.TotalVirtualMemorySize) * 100)
            }
            $Stats = Get-NetAdapter | Where-Object { $_.status -eq 'up' -and $_.name -in 'Ethernet', 'wi-fi' } | Get-NetAdapterStatistics
            $Disk = Get-Ciminstance -class Win32_PerfRawData_PerfDisk_LogicalDisk -filter "name= '_Total' " 
            $CPU = $CPU[1..49] + [int]$Performance['CPU']
            $RAM = $RAM[1..49] + [int]$Performance['RAM']
            $PageFile = $PageFile[1..49] + [int]$Performance['PageFile']

            if ($EthernetReceive) {
                # Ethernet Receive   
                [int[]]$recv = @(0) * $MaxStepsOnXAxis
                $Diff = $Stats.ReceivedBytes - $RecvPrev
                if ($diff -ge 0) {
                    
                    if ($RecvPrev) {
                        if ($diff -ge 1GB) {
                            $RecvUnit = 'Gb'
                        }
                        elseif ($diff -ge 1Mb) { 
                            $RecvUnit = 'Mb'
                        }
                        elseif ($diff -ge 1kb) { 
                            $RecvUnit = 'Kb'
                        }
                        $RecvPerSec = $RecvPerSec[1..49] + [int]$Diff
                    }
                    $RecvPrev = $Stats.ReceivedBytes
                    $Recv = $RecvPerSec.foreach( { $_ / (Invoke-Expression "1$RecvUnit") })
                    $max = ($Recv | Measure-Object -Maximum).maximum
                    $i = 2
                    while ($true) {
                        if (($Max / $i) -le $MaxStepsOnYAxis) {
                            $Recvstep = round($i)
                            break
                        }    
                        $i = $i + 1
                    }
                }
            } 
    
            if ($EthernetSend) {
                # Ethernet Sent   
                [int[]]$sent = @(0) * $MaxStepsOnXAxis
                $Diff = $Stats.SentBytes - $SentBytesPrev
                if ($diff -ge 0) {
                    
                    if ($SentBytesPrev) {
                        if ($diff -ge 1GB) {
                            $SentUnit = 'Gb'
                        }
                        elseif ($diff -ge 1Mb) { 
                            $SentUnit = 'Mb'
                        }
                        elseif ($diff -ge 1kb) { 
                            $SentUnit = 'Kb'
                        }
                        $SentPerSec = $SentPerSec[1..49] + [int]$Diff
                    }
                    
                    $SentBytesPrev = $Stats.SentBytes
                    $Sent = $SentPerSec.foreach( { $_ / (Invoke-Expression "1$SentUnit") })
                    $max = ($sent | Measure-Object -Maximum).maximum
                    $i = 2
                    while ($true) {
                        if (($Max / $i) -le $MaxStepsOnYAxis) {
                            $sentstep = round($i)
                            break
                        }    
                        $i = $i + 1
                    }
                }
            }
            $Disk = Get-Ciminstance -class Win32_PerfRawData_PerfDisk_LogicalDisk -filter "name= '_Total' " 
    
            if ($DiskRead) {
                # Disk Reads
                [int[]]$Writes = @(0) * $MaxStepsOnXAxis
                $Diff = $Disk.DiskReadBytesPersec - $DiskReadBytesPrev
                if ($diff -ge 0) {
                    if ($DiskReadBytesPrev) {
                        if ($diff -ge 1GB) {
                            $ReadUnit = 'Gb'
                        }
                        elseif ($diff -ge 1Mb) { 
                            $ReadUnit = 'Mb'
                        }
                        elseif ($diff -ge 1kb) { 
                            $ReadUnit = 'Kb'
                        }
                        $DiskReadsPerSec = $DiskReadsPerSec[1..49] + [int]$Diff
                    }
        
                    $DiskReadBytesPrev = $Disk.DiskReadBytesPersec 
                    $Reads = $DiskReadsPerSec.foreach( { $_ / (Invoke-Expression "1$SentUnit") })
                    $max = ($Reads | Measure-Object -Maximum).maximum
                    $i = 2
                    while ($true) {
                        if (($Max / $i) -le $MaxStepsOnYAxis) {
                            $ReadsStep = round($i)
                            break
                        }    
                        $i = $i + 1
                    }
                }
            }
            if ($DiskWrite) {

                # Disk Writes
                [int[]]$Writes = @(0) * $MaxStepsOnXAxis
                $Diff = $Disk.DiskWriteBytesPersec - $DiskWriteBytesPrev
                if ($diff -ge 0) {
        
                    if ($DiskWriteBytesPrev) {
                        if ($diff -ge 1GB) {
                            $WriteUnit = 'Gb'
                        }
                        elseif ($diff -ge 1Mb) { 
                            $WriteUnit = 'Mb'
                        }
                        elseif ($diff -ge 1kb) { 
                            $WriteUnit = 'Kb'
                        }
                        $DiskWritesPerSec = $DiskWritesPerSec[1..49] + [int]$Diff
                    }
        
                    $DiskWriteBytesPrev = $Disk.DiskWriteBytesPersec 
                    $Writes = $DiskWritesPerSec.foreach( { $_ / (Invoke-Expression "1$SentUnit") })
                    $max = ($Writes | Measure-Object -Maximum).maximum
                    $i = 2
                    while ($true) {
                        if (($Max / $i) -le $MaxStepsOnYAxis) {
                            $WritesStep = round($i)
                            break
                        }    
                        $i = $i + 1
                    }
                }
            }
            Clear-Host
            $PercentageStep = 10

            if ($Processor) {
                Show-Graph -datapoints $CPU -GraphTitle 'CPU [Percentage]' -YAxisStep (100 / $MaxStepsOnYAxis)
            }

            if ($PhysicalMemory) {
                Show-Graph -datapoints $RAM -GraphTitle 'RAM [Percentage]' -YAxisStep (100 / $MaxStepsOnYAxis)
            }

            if ($VirtualMemory) {
                Show-Graph -datapoints $PageFile -GraphTitle 'PageFile [Percentage]' -YAxisStep (100 / $MaxStepsOnYAxis)
            }

            if ($EthernetReceive) {
                Show-Graph -datapoints $Recv -GraphTitle  "$($Stats.name) - Received [${RecvUnit}ps]" -YAxisStep $Recvstep
            }

            if ($EthernetSend) {
                Show-Graph -datapoints $Sent -GraphTitle "$($Stats.name) - Send [${SentUnit}ps]" -YAxisStep $sentstep
            }

            if ($DiskRead) {
                Show-Graph -datapoints $Reads -GraphTitle "Disk - Reads [${ReadUnit}ps]" -YAxisStep $ReadsStep
            }
            
            if ($DiskWrite) {
                Show-Graph -datapoints $Writes -GraphTitle "Disk - Writes [${WriteUnit}ps]" -YAxisStep $WritesStep
            }
    
            # $Step = ($datapoints | measure -Maximum).maximum/ ($host.UI.RawUI.BufferSize.Height)
    
    
            # Show-Graph -datapoints $datapoints -GraphTitle 'Memory' -YAxisStep 10
            # Show-Graph -datapoints $datapoints -GraphTitle 'PageFile' -YAxisStep 10
            Start-Sleep -Seconds 1
            # Reset cursor and overwrite prior output
            # $host.UI.RawUI.CursorPosition = @{x=0; y=1}
    
            # $Step = ($datapoints | measure -Maximum).maximum/ ($host.UI.RawUI.BufferSize.Height)
        }
        catch {
            Clear-Host
        }
    } while ($true)
}

Invoke-PerfMon -Processor:$Processor `
    -PhysicalMemory:$PhysicalMemory `
    -VirtualMemory:$VirtualMemory `
    -EthernetSend:$EthernetSend `
    -EthernetReceive:$EthernetReceive `
    -DiskRead:$DiskRead `
    -DiskWrite:$DiskWrite `
    -MaxStepsOnYAxis:$MaxStepsOnYAxis `
    -MaxStepsOnXAxis:$MaxStepsOnXAxis