<#

    Get and Wait on PVE task.

#>
function Start-PVEWait {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)][string]$ProxmoxAPI,
        [Parameter(Mandatory)][object]$Headers,
        [Parameter(Mandatory)][string]$Node,
        [Parameter(Mandatory)][string]$Taskid
    )

    $TimeoutSeconds = 2000
    $StartTime = Get-Date
    $EndTime = $StartTime.AddSeconds($TimeoutSeconds)

    do {
        $TaskStatus = Invoke-RestMethod -Uri "$ProxmoxAPI/nodes/$Node/tasks/$Taskid/status" -Headers $Headers -Verbose:$false

        if ($TaskStatus.data.status -eq "stopped") {
            Write-Progress -Activity "Waiting for PVE Task ($($TaskStatus.data.type))" -Completed

            if ($TaskStatus.data.exitstatus -ne "OK") {
                throw "PVE Task failed: $($TaskStatus.data.exitstatus)"
            }

            return
        }
        elseif ((Get-Date) -ge $EndTime) {
            Write-Progress -Activity "Waiting for PVE Task ($($TaskStatus.data.type))" -Completed
            throw "PVE Task timeout reached."
        }

        $Elapsed = (Get-Date) - $StartTime
        $Percent = [math]::Min(($Elapsed.TotalSeconds / $TimeoutSeconds) * 100, 100)

        Write-Progress -Activity "Waiting for PVE Task ($($TaskStatus.data.type))" -Status "Running" -PercentComplete $Percent
        Start-Sleep -Seconds 1

    } while ($true)
}