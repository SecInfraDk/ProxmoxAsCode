# Documentation
After PVE cluster installed and configured.

1. Create PowerShell API token with required permissions.

2. Run ProxmoxAsCode\BuildScripts\Create-ProxmoxConfig.ps1
- This will create Proxmox-Connection.json file.

3. Run ProxmoxAsCode\BuildScripts\Create-PVEDeploymentServer.ps1
- This will prepare the Core Deployment server from where all future VMs are created from.

4. Run ProxmoxAsCode\Scripts\New-PVEVMTemplate.ps1
- Use this to create new Windows Server template, every time the Windows ISO have been updated, for at fully patched template.

5. Run ....


