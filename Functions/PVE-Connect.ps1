<#

    Connect to PVE cluster.

#>
function PVE-Connect {
    [CmdletBinding()]
    Param(
        [string]$Authkey,
        [string]$Hostaddr,
        [string]$ConfigPath = "C:\SSScripts\Proxmox-Connection.json",
        [switch]$IgnoreCertificateErrors
    )


    # Load connection configuration if parameters are not supplied.
    # ------------------------------------------------------------
    if (-not ($Authkey -and $Hostaddr)) {

        if (-not (Test-Path -LiteralPath $ConfigPath -PathType Leaf)) {

            Add-Type -AssemblyName System.Windows.Forms

            $FileDialog = New-Object System.Windows.Forms.OpenFileDialog
            $FileDialog.InitialDirectory = Split-Path $ConfigPath -Parent
            $FileDialog.Filter = "JSON files (*.json)|*.json"
            $FileDialog.Title = "Select Proxmox Connection file"
            $FileDialog.FileName = "Proxmox-Connection.json"
            $FileDialog.CheckFileExists = $true

            # Workaround show file name in dialog
            # ------------------------------------------------------------
            $Timer = New-Object System.Windows.Forms.Timer
            $Timer.Interval = 100
            $Timer.Add_Tick({ $Timer.Stop(); [System.Windows.Forms.SendKeys]::SendWait("{HOME}") })
            $Timer.Start()

            try {
                $Result = $FileDialog.ShowDialog()
            }
            finally {
                $Timer.Stop()
                $Timer.Dispose()
            }

            if ($Result -ne [System.Windows.Forms.DialogResult]::OK) {
                throw "No Proxmox connection file selected."
            }

            $ConfigPath = $FileDialog.FileName
        }

        $PVESecret = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json

        $Authkey = "$($PVESecret.User)!$($PVESecret.TokenID)=$($PVESecret.Token)"
        $Hostaddr = $PVESecret.Host
    }


    # HTTP Headers for connection.
    # ------------------------------------------------------------
    $DefaultHeaders = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $DefaultHeaders.Add("Authorization", "PVEAPIToken=$Authkey")
    $DefaultHeaders.Add("Accept", "application/json")


    # Ignore Self Signed Cert.
    # ------------------------------------------------------------
if ($IgnoreCertificateErrors) {

    if (-not ("TrustAllCertsPolicy" -as [type])) {
        Add-Type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;

public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(
        ServicePoint srvPoint,
        X509Certificate certificate,
        WebRequest request,
        int certificateProblem) {
        return true;
    }
}
"@
    }

    [Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
}

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12


    # Proxmox API address.
    # ------------------------------------------------------------
    $DefaultProxmoxAPI = "https://${Hostaddr}:8006/api2/json"


    return [PSCustomObject]@{
        PVEAPI  = $DefaultProxmoxAPI
        Headers = $DefaultHeaders
    }
}