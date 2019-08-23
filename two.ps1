<#
    .SYNOPSIS
        Checks VM activity in the past
    .DESCRIPTION
        Checks multiple activity indicators for information in order to state if VM is performing any activity
    .EXAMPLE
        get-vm 'abc' | .\check-nonactivevms.ps1 -CpuUsage -MemUsage -IOUsage -NetworkUsage -PastDays 31 -NetworkCards -IntervalMin 120 -Threshold 1
    .EXAMPLE
        .\check-nonactivevms.ps1 -CpuUsage -MemUsage -IOUsage -NetworkUsage -PastDays 31 -NetworkCards -IntervalMin 120 -Threshold 1 -vm (get-vm myVM1a)
    .EXAMPLE
        .\check-nonactivevms.ps1 -CpuUsage -MemUsage -IOUsage -NetworkUsage -PastDays 31 -NetworkCards -IntervalMin 120 -Threshold 1 -vm (get-vm myVM1a,myVM2b)
    .EXAMPLE
        (get-vm myVM1a,myVM2b) | .\check-nonactivevms.ps1 -CpuUsage -MemUsage -IOUsage -NetworkUsage -PastDays 31 -NetworkCards -IntervalMin 120 -Threshold 1
    .INPUTS
        Activity indicators
    .OUTPUTS
        VM array with their activity indicators
    .NOTES
        General notes
    .COMPONENT
        The component this cmdlet belongs to
    .ROLE
        The role this cmdlet belongs to
    .FUNCTIONALITY
        The functionality that best describes this cmdlet
    .LINK
        https://github.com/qlikq/Check-VMActivityState
    #>

    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    Param (
        # Virtual machine or array of them, this parameter expects the virtualmachine object coming from get-vm ... cmdlet
        [Parameter(Mandatory, 
            ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [VMware.VimAutomation.ViCore.Impl.V1.VM.UniversalVirtualMachineImpl[]]$VM,

        # Indicate if you would like to gather information about VM Avg cpu usage, returned in %
         [switch]$CpuUsage,

        # Indicate if you would like to gather information about VM Avg memory usage, returned in %
        [switch]$MemUsage,

        # Indicate if you would like to gather information about VM Avg i/o usage, returned in kb/s
        [switch]$IOUsage,

        # Indicate if you would like to gather information about VM Avg network usage, returned in kb/s
        [switch]$NetworkUsage,

        # It will be used to make the start date, we will check statistics for the past Xnumber of PastDays, keep in mind that your VirtualCenter has to handle that number of days
        [Parameter(Mandatory)]
        [byte]$PastDays,

        # If specified, you will get additional property about network card states, to check if the network card is connected to network or not
        [switch]$NetworkCards,

        # Invervalmin for the statistic data to be used, 1,5,30,60,120 for example
        [Parameter(Mandatory)]
        [byte]$IntervalMin,

        # Initial version of threshold implementation, it is used to mark as not active vms with indicators below that given threshold
        [byte]$Threshold = 0

    )

    Begin {
    $params = @{
        IntervalMin = $intervalmin
        Start       = (Get-Date).AddDays(-$PastDays)
    }
    $si = get-view -id serviceinstance
    #Retrieve ServiceInstance view

    $pm = get-view -id $si.Content.PerfManager
    #Retrieve Performance Manager view
    
    $VMCpuAvgPercentageCounterID = ($pm.PerfCounter | Where-Object {$_.NameInfo.key -eq 'usage' -and $_.GroupInfo.Key -eq 'cpu' -and $_.RollupType -eq 'average'}).Key
    $VMMemAvgPercentageCounterID = ($pm.PerfCounter | Where-Object {$_.NameInfo.key -eq 'usage' -and $_.GroupInfo.Key -eq 'mem' -and $_.RollupType -eq 'average'}).Key
    $CPUPerfMetricID = New-Object VMware.Vim.PerfMetricId -Property @{CounterId = $VMCpuAvgPercentageCounterID; Instance = '' }
    $MEMPerfMetricID = New-Object VMware.Vim.PerfMetricId -Property @{CounterId = $VMMemAvgPercentageCounterID; Instance = '' }
    #Set Instance to '' as we want to get all cpu avg

    }

    Process {

    Foreach ($VMItem in $VM){

        switch ($true){
            {$NetworkUsage}{
            $ntwkAvgUsage = ($VMItem|
                get-stat -Stat 'net.usage.average' @params|
                measure-object  -Property value -Average).Average
            }
            {$cpuUsage}{
                $PerfSpecProps = @{
                    Entity = $vmitem.extensiondata.moref
                    starttime = (get-date).AddDays(-$PastDays)
                    endtime = (get-date)
                    metricid = $PerfMetricID
                    Format = 'csv'
                }
            
                $QueryPerfSpec = New-Object VMware.Vim.PerfQuerySpec -Property $PerfSpecProps
                $data = $pm.QueryPerf($QueryPerfSpec)
                $cpuAvgUsage=($data[0].Value[0].value -split ',' |%{$_ / 100 } | Measure-Object -Average).Average
                }
            {$MemUsage}{
                $PerfSpecProps = @{
                    Entity = $vmitem.extensiondata.moref
                    starttime = (get-date).AddDays(-$PastDays)
                    endtime = (get-date)
                    metricid = $MEMPerfMetricID
                    Format = 'csv'
                }
            
                $QueryPerfSpec = New-Object VMware.Vim.PerfQuerySpec -Property $PerfSpecProps
                $data = $pm.QueryPerf($QueryPerfSpec)
                $MemAvgUsage=($data[0].Value[0].value -split ',' |%{$_ / 100 } | Measure-Object -Average).Average
            }
            {$IOUsage}{
                $DiskAvgUsage = ($VMItem|
                    get-stat -Stat 'disk.usage.average' @params|
                    measure-object  -Property value -Average).Average
                }
            {$NetworkCards}{
                $NetworkConnected = ($VMItem.ExtensionData.Config.Hardware.Device |
                Where-Object {$_ -is [VMware.Vim.VirtualEthernetCard]}).Connectable.Connected -join ','
            }
        }

        [PSCustomObject]@{
            'VMName' = $VMItem.Name
            "${PastDays}dayAvgCpuUsagePercent" = [math]::round($cpuAvgUsage,2)
            "${PastDays}dayAvgMemUsagePercent" = [math]::round($MemAvgUsage,2)
            "${PastDays}AvgNetUsageKB" = [math]::round($ntwkAvgUsage,2)
            "${PastDays}DiskNetUsageKB" = [math]::round($DiskAvgUsage,2)
            "${PastDays}NetworkCardsConnected" = $NetworkConnected
            "thresholdUsed" = $Threshold
            "NotActive" = if ($cpuAvgUsage -le $Threshold -or $ntwkAvgUsage -le $Threshold -or $DiskAvgUsage -le $Threshold) {$True} else {$False}
            }
        }
    }

    End {
        
    }
