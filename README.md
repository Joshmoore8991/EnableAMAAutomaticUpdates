Enable Automatic Upgrade for Azure Monitor Agent (AMA)
Overview
This PowerShell script enables Automatic Upgrade for the Azure Monitor Agent (AMA) extensions across:

Azure Virtual Machines (AzVM)

Azure Arc-enabled Servers (AzArc)

It ensures that all applicable machines automatically upgrade their monitoring agent without manual intervention, helping maintain better security, performance, and reliability.

Features
✅ Detects and processes all subscriptions available to the user.
✅ Supports both Azure VMs and Arc Machines.
✅ Dynamically detects Linux or Windows OS and applies the correct AMA extension type.
✅ Preserves existing settings and protected settings during upgrade.
✅ Automatically installs missing Az modules if needed.
✅ Handles missing or incomplete AMA extension data gracefully without crashing.

Requirements
PowerShell 5.1 (Windows) or PowerShell 7.x (Cross-platform)

Azure PowerShell Modules:

Az.Accounts

Az.Compute

Az.ConnectedMachine

Azure Permissions:

Reader and Contributor rights on target subscriptions/machines

Network Access:

Azure Resource Manager endpoints

Installation
Save the script as Enable-AutomaticUpgradeAMA.ps1.

Open PowerShell as Administrator.

(Optional) Allow running local scripts:

powershell
Copy
Edit
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process
Ensure you are logged into Azure:

powershell
Copy
Edit
Connect-AzAccount
Usage
Run the script by specifying the environment you want to target:

powershell
Copy
Edit
.\Enable-AutomaticUpgradeAMA.ps1 -Environment <AzVM | AzArc | Both>
Parameters

Name	Type	Description	Required
Environment	string	Target environment: AzVM, AzArc, or Both	Yes
Examples
Enable Automatic Upgrade for only Azure VMs:

powershell
Copy
Edit
.\Enable-AutomaticUpgradeAMA.ps1 -Environment AzVM
Enable Automatic Upgrade for only Azure Arc Machines:

powershell
Copy
Edit
.\Enable-AutomaticUpgradeAMA.ps1 -Environment AzArc
Enable Automatic Upgrade for both VMs and Arc Machines:

powershell
Copy
Edit
.\Enable-AutomaticUpgradeAMA.ps1 -Environment Both
Run with verbose output to troubleshoot or monitor actions:

powershell
Copy
Edit
.\Enable-AutomaticUpgradeAMA.ps1 -Environment Both -Verbose
How It Works
Connects to Azure and loops through all available subscriptions.

Retrieves all Virtual Machines and/or Arc-enabled Machines.

For each machine:

Checks if the Azure Monitor Agent extension is installed.

Verifies if Automatic Upgrade is already enabled.

If not enabled:

Determines OS type (Windows or Linux).

Reapplies the extension with EnableAutomaticUpgrade = true, preserving existing settings.

Outputs status for each machine processed.

Notes
Only machines with the Microsoft.Azure.Monitor extension installed will be affected.

Machines that already have EnableAutomaticUpgrade = true are skipped.

The script is safe to rerun multiple times; it will not reapply if not needed.

Azure Arc updates use Update-AzConnectedMachineExtension; Azure VM updates use Set-AzVMExtension.

Troubleshooting
Modules not found:

The script auto-installs missing modules, but you can also manually run:

powershell
Copy
Edit
Install-Module Az -Scope CurrentUser -Repository PSGallery -Force
Permission errors:

Make sure your Azure account has Contributor permissions to modify machine extensions.

Execution Policy errors:

Set execution policy as shown above if your environment blocks running scripts.

License
This project is licensed under the MIT License.

Author
Script Owner: Joshua Moore

Date Created: April 2025

Last Updated: April 2025
