<#
    .SYNOPSIS
        Checks VM activity in the past
    .DESCRIPTION
        Checks multiple activity indicators for information in order to state if VM is performing any activity
    .EXAMPLE
        Check-NonActiveVMs -Indicator all
    .EXAMPLE
        Another example of how to use this cmdlet
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
    [Alias()]
    [OutputType([PSCustomObject])]
    Param (
        # Param1 help description
        [Parameter(Mandatory, 
            ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [VMware.VimAutomation.ViCore.Impl.V1.VM.UniversalVirtualMachineImpl[]]$VM,

        # Param2 help description
         [switch]$CpuUsage,

        # Param2 help description
        [switch]$MemUsage,

        # Param2 help description
        [switch]$IOUsage,

        # Param3 help description
        [switch]$NetworkUsage,

        # Param3 help description
        [Parameter(Mandatory)]
        [byte]$PastDays,

        # Param3 help description
        [Parameter(Mandatory)]
        [switch]$NetworkCards,

        # Param3 help description
        [Parameter(Mandatory)]
        [byte]$IntervalMin,

        # Param3 help description
        [byte]$Threshold = 0

    )

    Begin {
        #$vms = Get-VM
    }

    Process {
    Foreach ($VMItem in $VM){
        if($NetworkUsage){
            $ntwkAvgUsage = ($VMItem|get-stat -Stat 'net.usage.average' -intervalMin $intervalmin -Start (get-date).AddDays(-$PastDays)|measure-object  -Property value -Average).Average
        }
        if ($cpuUsage){
            $cpuAvgUsage =  ($VMItem|get-stat -Stat 'cpu.usage.average' -intervalMin $intervalmin -Start (get-date).AddDays(-$PastDays)|measure-object  -Property value -Average).Average
        }
        if ($MemUsage){
            $MemAvgUsage = ($VMItem|get-stat -Stat 'mem.usage.average' -intervalMin $intervalmin -Start (get-date).AddDays(-$PastDays)|measure-object  -Property value -Average).Average
        }
        if ($IOUsage){
            $DiskAvgUsage = ($VMItem|get-stat -Stat 'disk.usage.average' -intervalMin $intervalmin -Start (get-date).AddDays(-$PastDays)|measure-object  -Property value -Average).Average
        }
        if ($NetworkCards){
            $NetworkConnected = ($VMItem.ExtensionData.Config.Hardware.Device |? {$_ -is [VMware.Vim.VirtualEthernetCard]}).Connectable.Connected -join ','
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
