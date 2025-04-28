param (
    [Parameter(Mandatory)]
    [ValidateSet("AzVM", "AzArc", "Both")]
    [string]$Environment = 'Both'
)

# Install Az Module If Needed
function Install-Module-If-Needed {
    param([string]$ModuleName)
    if (Get-Module -ListAvailable -Name $ModuleName -Verbose:$false) {
        Write-Host "Module '$($ModuleName)' already exists." -ForegroundColor Green
    } else {
        Write-Host "Module '$($ModuleName)' not found. Installing..." -ForegroundColor Yellow
        Install-Module $ModuleName -Force -AllowClobber -ErrorAction Stop
        Write-Host "Module '$($ModuleName)' installed." -ForegroundColor Green
    }
}

# Install required modules
Install-Module-If-Needed Az.Accounts
Install-Module-If-Needed Az.Compute
Install-Module-If-Needed Az.ConnectedMachine

# Connect to Azure
try {
    Connect-AzAccount -ErrorAction Stop -WarningAction SilentlyContinue | Out-Null
} catch {
    Write-Warning "Cannot connect to Azure Cloud. Check your credentials."
    break
}

# Get all subscriptions
$azSubs = Get-AzSubscription

foreach ($azSub in $azSubs) {
    Set-AzContext -Subscription $azSub | Out-Null
    Write-Host "Processing subscription: $($azSub.Name)" -ForegroundColor Cyan

    if ($Environment -eq "AzVM" -or $Environment -eq "Both") {
        # Handle Azure VMs
        $azVMs = Get-AzVM -ErrorAction SilentlyContinue
        if ($azVMs) {
            foreach ($vm in $azVMs) {
                $amaExtension = Get-AzVMExtension -VMName $vm.Name -ResourceGroupName $vm.ResourceGroupName `
                    | Where-Object { $_.Publisher -eq "Microsoft.Azure.Monitor" }

                if ($amaExtension) {
                    if (-not $amaExtension.EnableAutomaticUpgrade) {
                        Write-Host "Enabling Automatic Upgrade for VM: $($vm.Name)" -ForegroundColor Yellow

                        # Determine OS type
                        $vmOS = $vm.StorageProfile.OSDisk.OSType
                        if ($vmOS -eq "Linux") {
                            $extensionType = "AzureMonitorLinuxAgent"
                        } else {
                            $extensionType = "AzureMonitorWindowsAgent"
                        }

                        # Reapply extension with EnableAutomaticUpgrade
                        Set-AzVMExtension -ResourceGroupName $vm.ResourceGroupName `
                                          -VMName $vm.Name `
                                          -Name $amaExtension.Name `
                                          -Publisher $amaExtension.Publisher `
                                          -ExtensionType $extensionType `
                                          -TypeHandlerVersion $amaExtension.TypeHandlerVersion `
                                          -Settings $amaExtension.Settings `
                                          -ProtectedSettings $amaExtension.ProtectedSettings `
                                          -Location $vm.Location `
                                          -EnableAutomaticUpgrade $true `
                                          -ForceRerun ($([guid]::NewGuid().ToString())) `
                                          -ErrorAction Stop

                        Write-Host "Automatic Upgrade enabled for VM: $($vm.Name)" -ForegroundColor Green
                    } else {
                        Write-Host "Automatic Upgrade already enabled for VM: $($vm.Name)" -ForegroundColor Green
                    }
                }
            }
        } else {
            Write-Host "No Azure VMs found in subscription: $($azSub.Name)" -ForegroundColor DarkYellow
        }
    }

    if ($Environment -eq "AzArc" -or $Environment -eq "Both") {
        # Handle Azure Arc Servers
        $azArcServers = Get-AzConnectedMachine -ErrorAction SilentlyContinue
        if ($azArcServers) {
            foreach ($arcMachine in $azArcServers) {
                $amaExtension = Get-AzConnectedMachineExtension -MachineName $arcMachine.Name -ResourceGroupName $arcMachine.ResourceGroupName `
                    | Where-Object { $_.Publisher -eq "Microsoft.Azure.Monitor" }

                if ($amaExtension) {
                    if (-not $amaExtension.EnableAutomaticUpgrade) {
                        Write-Host "Enabling Automatic Upgrade for Arc Server: $($arcMachine.Name)" -ForegroundColor Yellow

                        Update-AzConnectedMachineExtension -Name $amaExtension.Name `
                                                           -ResourceGroupName $arcMachine.ResourceGroupName `
                                                           -MachineName $arcMachine.Name `
                                                           -EnableAutomaticUpgrade $true `
                                                           -Settings $amaExtension.Settings `
                                                           -ProtectedSettings $amaExtension.ProtectedSettings `
                                                           -ErrorAction Stop

                        Write-Host "Automatic Upgrade enabled for Arc Server: $($arcMachine.Name)" -ForegroundColor Green
                    } else {
                        Write-Host "Automatic Upgrade already enabled for Arc Server: $($arcMachine.Name)" -ForegroundColor Green
                    }
                }
            }
        } else {
            Write-Host "No Azure Arc Servers found in subscription: $($azSub.Name)" -ForegroundColor DarkYellow
        }
    }
}
