<#

    Select list of VMs to be removed

#>


# Path to PVE scripts and Functions.
# ------------------------------------------------------------
if ($PSScriptRoot -and $PSScriptRoot -ne "") {
    $RootPath = $PSScriptRoot
} else {
    $RootPath  = "C:\Scripts"
}


# Import PVE modules
# ------------------------------------------------------------
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force -Confirm:$false
Get-ChildItem -Path $RootPath -Recurse -File -Filter "*PVE*.ps1" |
    Where-Object { $_.DirectoryName -like "*\Functions" } |
    ForEach-Object { Import-Module -Name $_.FullName -Force }


# Import Shared modules
# ------------------------------------------------------------
# Rember to update the PATH
Get-ChildItem -Path $RootPath -Recurse -File -Filter "*.psm1" |
    ForEach-Object { Import-Module -Name $_.FullName -Force }


# Connect to PVE Cluster
$PVEConnect = PVE-Connect -ConfigPath $RootPath


# Get ALL VMs on the "Cluster"
# ------------------------------------------------------------
$AllVMs = (Invoke-RestMethod -Uri "$($PVEConnect.PVEAPI)/cluster/resources?type=vm" -Headers $PVEConnect.Headers -Verbose:$false).data | Where {$_.template -eq 0}


# Select VMs to be removed.
# ------------------------------------------------------------
$Selected = $AllVMs | Select-Object @{Name='VMID'; Expression={ "$($_.vmid)" }}, Name | Out-GridView -Title "Select VMs to be deleted" -OutputMode Multiple


foreach ($VM in $Selected) {
    $Node   = $($AllVMs | Where {$_.VMID -eq $VM.VMID}).Node
    $Status = $($AllVMs | Where {$_.VMID -eq $VM.VMID}).status


    # If Running, STOP.
    if ($Status -eq "running") {
        $Stop = Invoke-RestMethod -Uri "$($PVEConnect.PVEAPI)/nodes/$Node/qemu/$($VM.VMID)/status/stop" -Headers $PVEConnect.Headers -Method Post
        Start-PVEWait -ProxmoxAPI $PVEConnect.PVEAPI -Headers $PVEConnect.Headers -Node $Node -Taskid $Stop.data
    }

    "$($PVEConnect.PVEAPI)/nodes/$Node/qemu/$($VM.VMID)"
    #$Delete = Invoke-RestMethod -Uri "$($PVEConnect.PVEAPI)/nodes/$Node/qemu/$($VM.VMID)" -Headers $PVEConnect.Headers -Method Delete
    #Start-PVEWait -ProxmoxAPI $PVEConnect.PVEAPI -Headers $PVEConnect.Headers -Node $Node -Taskid $Delete.Data
}
