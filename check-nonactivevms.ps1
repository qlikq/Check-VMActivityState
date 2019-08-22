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

    [CmdletBinding(DefaultParameterSetName='Default Parameter Set Name',
        SupportsShouldProcess,
        PositionalBinding,
        HelpUri = 'http://www.microsoft.com/',
        ConfirmImpact='Medium')]
    [Alias()]
    [OutputType([String])]
    Param (
        # Param1 help description
        [Parameter(Mandatory, 
            ValueFromPipeline,
            ValueFromPipelineByPropertyName, 
            ValueFromRemainingArguments, 
            Position=0,
            ParameterSetName='Default Parameter Set Name')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidateCount(0,5)]
        [ValidateSet('sun', 'moon', 'earth')]
        [Alias('p1')] 
        [String]$Param1,

        # Param2 help description
        [Parameter(ParameterSetName='Default Parameter Set Name')]
        [AllowNull()]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [ValidateScript({$True})]
        [ValidateRange(0,5)]
        [int]$Param2,

        # Param3 help description
        [Parameter(ParameterSetName='Another Parameter Set Name')]
        [ValidatePattern("[a-z]*")]
        [ValidateLength(0,15)]
        [String]$Param3
    )

    Begin {
        $vms = Get-VM
    }

    Process {
        If ($PSCmdlet.ShouldProcess('Target', 'Operation')) {
            [PSCustomObject]@{
                '30dayAvgCpuUsagePercent' = 'fd'
                '30dayAvgMemUsagePercent' = 'two'
                '30dayAvgNetUsageKB' = 'three'
                '30dayAvgIOUsageKB' = 'four'
                }
        }
    }

    End {
    }
