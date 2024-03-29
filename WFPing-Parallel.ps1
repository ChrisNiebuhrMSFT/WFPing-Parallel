<#
Disclaimer

This sample script is not supported under any Microsoft standard support program or service. 
The sample script is provided AS IS without warranty of any kind. Microsoft further disclaims 
all implied warranties including, without limitation, any implied warranties of merchantability 
or of fitness for a particular purpose. The entire risk arising out of the use or performance 
of the sample scripts and documentation remains with you. In no event shall Microsoft, its authors, 
or anyone else involved in the creation, production, or delivery of the scripts be liable for 
any damages whatsoever (including, without limitation, damages for loss of business profits, 
business interruption, loss of business information, or other pecuniary loss) arising out of the 
use of or inability to use the sample scripts or documentation, even if Microsoft has been advised 
of the possibility of such damages
#>

<#
.SYNOPSIS
   Pings an Array of Computers in parallel
.DESCRIPTION
   Pings an Array of Computers in parallel and gather some informations
.EXAMPLE
   Ping-Parallel -Computers "Machine1", "Machine2", "microsoft.com", "bing.com"
.EXAMPLE
   $computers = Get-Content .\Computers.txt
   Ping-Parallel -Computers $computers
.EXAMPLE
   #You can also use an Alias
   pp -Computers ""Machine1", "Machine2", "microsoft.com", "bing.com"
.INPUTS
  Stringarray of Computernames 
.OUTPUTS
   PSCustomObject with some Properties (Online - Array, Offline - Array , PercentOnline - Double, PercentOffline -Double, TakenTime - Timespan)
.NOTES
   Requires PowerShell v3 (Workflows), Firewall is configured for ICMP (Ping requests) 
   Author:  Microsoft - Chris Niebuhr
   Date:    10/20/2016
   Update:  02/20/2018 Using the WMIPingProvider with Timeout option
#>
Workflow Ping-Parallel
{
    [CmdletBinding()]
    [Alias("pp")]
    Param
    (
        [ValidateNotNullOrEmpty()]
        [Parameter(HelpMessage="Please provide an Array of Sources you want to Ping.")]
        [string[]]
        $Computers, 
        [ValidateRange(1,1000)]
        [Parameter(HelpMessage="Please provide a Timetout in ms for the Ping-Request")]
        [int32]
        $Timeout = 500
    )

    $counter = 0
    $online  = @()
    $offline = @()
    $start = Get-Date

    foreach -parallel ($computer in $Computers)
    {
        $tmpResult = Get-WmiObject -Query "Select * From Win32_Pingstatus Where Address='$computer' AND Timeout=$Timeout"
        If($tmpResult.StatusCode -eq 0)
        {
            Write-Verbose "$computer available"
            $Workflow:counter++
            $Workflow:online += $computer 
        }
        Else
        {
            Write-Verbose "$computer not available"
            $Workflow:offline += $computer
        }
    }
    Write-Verbose "$counter / $($computers.Count) Systems are available"
    $result = inlinescript
    {
        $res = New-Object PSObject | Select Online, Offline, PercentOnline, PercentOffline, TakenTime 
        $res.Online  = $Using:online
        $res.Offline = $Using:offline
        $res.PercentOnline = $Using:counter * 100 / $Using:Computers.Count
        $res.PercentOffline = 100-$res.PercentOnline
        $res.TakenTime = (Get-Date) - $Using:start
        $res
    }
    $result
} 
