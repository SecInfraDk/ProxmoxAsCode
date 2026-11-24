<# 
    
    List Windows Server Versions avalible on Microsoft Evaluation Center, and download the selected ISO to PVE cluster.

    And Download latest version of the VirtIO-WIN drivers.
    https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-virtio/virtio-win.iso
    
#>

# Define OS ISO files to download
# ------------------------------------------------------------
$EvalCenter = Invoke-WebRequest -Uri "https://www.microsoft.com/en-us/evalcenter" -UseBasicParsing
$EvalVersions = ($EvalCenter.links | where {$_.href -like "*evaluate-windows-server-20*"}).href | 
    ForEach-Object { [regex]::Match($_, '\d{4}(?=-|$)').Value } |
        Sort-Object -Unique
$ServerVersionsISO = $EvalVersions | Out-GridView -Title "Select the Windows Server versions to Download" -OutputMode Multiple


<# Get all required json configurations #>


# Load Windows Forms
# ------------------------------------------------------------
Add-Type -AssemblyName System.Windows.Forms
$FileDialog = New-Object System.Windows.Forms.OpenFileDialog
$FileDialog.Filter = "JSON files (*.json)|*.json"


# Open PVE Secrets file
# ------------------------------------------------------------
$FileDialog.Title  = "Select Proxmox Secrets file"
if ($FileDialog.ShowDialog() -eq "OK") {
    $PVESecret  = Get-Content $FileDialog.FileName | Convertfrom-Json
}
else {
    Write-Warning "No file selected"

    # Needs Update
    Write-Host "Download and execute `"ProxmoxAsCode/BuildScripts/Create-ProxmoxConfig.ps1`" and rerun this script"
}


# Required to import unsigned modules
# ------------------------------------------------------------
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force -Confirm:$false


# Import PVE modules
# ------------------------------------------------------------
Get-ChildItem -Path "C:\Scripts\" -Recurse -File -Filter "*PVE*.ps1" |
    Where-Object { $_.DirectoryName -like "*\Functions" } |
    ForEach-Object { Import-Module -Name $_.FullName -Force }


# Connect to PVE Cluster
# -------------------.-----------------------------------------
if ($PVESecret.count -gt 1) {
    $PVESecret = $PVESecret | Out-GridView -Title "Select `"Master`" NODE" -OutputMode Single
}
$PVEConnect = PVE-Connect -Authkey "$($PVESecret.User)!$($PVESecret.TokenID)=$($PVESecret.Token)" -Hostaddr $($PVESecret.Host)


# Get information required to create the template (VM)
# ------------------------------------------------------------
$PVELocation = Get-PVELocation -ProxmoxAPI $PVEConnect.PVEAPI -Headers $PVEConnect.Headers
$ISOStorage  = ((Invoke-RestMethod -Uri "$($PVEConnect.PVEAPI)/nodes/$($PVELocation.name)/storage" -Headers $($PVEConnect.Headers)).data | Where {$_.content -like "*iso*" -and $_.type -eq "dir"}).storage


# Download Windows Server EVAL Isos
# ------------------------------------------------------------
$DownloadResults = @()
$ServerVersionsISO | Foreach {

    $response = Invoke-WebRequest -Uri "https://www.microsoft.com/en-us/evalcenter/download-windows-server-$($_)" -UseBasicParsing
    $DownloadUrl = ($response.Links | Where { $_.'aria-label' -like "*ISO*en-US*" }).href

    $DownloadBody = "content=iso"
    $DownloadBody += "&node=$($PVELocation.name)"
    $DownloadBody += "&url=$([uri]::EscapeDataString($DownloadUrl))"
    $DownloadBody += "&filename=$([uri]::EscapeDataString("Server_$($_)_Eval.iso"))"

    $DownloadResults += [pscustomobject]@{
        Version = $($_);
        Result = $(Invoke-RestMethod -Method POST -Uri "$($PVEConnect.PVEAPI)/nodes/$($PVELocation.name)/storage/$ISOStorage/download-url" -Headers $($PVEConnect.Headers) -Body $DownloadBody).data
    }
}


# Download VirtIO Windows Drivers.
# ------------------------------------------------------------
$DownloadBody  = "content=iso"
$DownloadBody += "&node=$($PVELocation.name)"
$DownloadBody += "&url=$([uri]::EscapeDataString("https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-virtio/virtio-win.iso"))"
$DownloadBody += "&filename=$([uri]::EscapeDataString("virtio-win.iso"))"

$DriverResult = Invoke-RestMethod -Method POST -Uri "$($PVEConnect.PVEAPI)/nodes/$($PVELocation.name)/storage/$ISOStorage/download-url" -Headers $($PVEConnect.Headers) -Body $DownloadBody
$DownloadResults += [pscustomobject]@{
    Version = "";
    Result = $DriverResult.data
}


# Wait all downloads.
# ------------------------------------------------------------
$DownloadResults | Foreach {
    Start-PVEWait -ProxmoxAPI $($PVEConnect.PVEAPI) -Headers $PVEConnect.Headers -node $($PVELocation.Name) -taskid $_.Result
}
