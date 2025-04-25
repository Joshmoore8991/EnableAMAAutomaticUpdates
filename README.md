# EnableAMAAutomaticUpdates
Enable Automatic Updates for AMA Agents


How the Script Works
Install Required Modules:

The script checks if the required Azure PowerShell modules (Az.Accounts, Az.Compute, and Az.ConnectedMachine) are installed. If any are missing, it automatically installs them.

Azure Login:

The script attempts to connect to your Azure account using Connect-AzAccount. Ensure that your Azure credentials are valid.

Subscription Iteration:

The script retrieves a list of all Azure subscriptions and sets the context for each subscription one by one.

Azure VMs Handling:

If the environment is set to AzVM or Both, it retrieves a list of all Azure VMs.

For each VM, it checks whether the AMA extension is installed and whether automatic upgrade is enabled.

If the automatic upgrade is not enabled, the script enables it.

Azure Arc Servers Handling:

If the environment is set to AzArc or Both, it retrieves a list of all Azure Arc Servers.

For each Arc server, it checks whether the AMA extension is installed and whether automatic upgrade is enabled.

If the automatic upgrade is not enabled, the script enables it.

Error Handling
Connection Issues: If the script fails to connect to Azure, it will display a warning and exit.

No VMs/Arc Servers: If no VMs or Arc Servers are found in the selected subscription, a message will be displayed indicating this.

Output
Verbose Output: The script provides detailed verbose messages during its execution. To see these, ensure that $VerbosePreference is set to Continue or use Write-Verbose for additional details.

Success/Failure Messages: After the script runs, it will display messages indicating whether automatic upgrade was enabled or already enabled for each VM/Arc Server.

Troubleshooting
Cannot Connect to Azure: Ensure that your credentials are valid and you are logged into Azure with sufficient permissions.

Missing Modules: The script attempts to install the necessary modules. If there is an issue with module installation, make sure your machine is connected to the internet and has access to the PowerShell Gallery.
