param (
    [Parameter(Mandatory)]    
    [ValidateSet("AzVM", "AzArc", "Both")]
    [String]$Environment = 'Both'   
)

#! Install Az Module If Needed
function Install-Module-If-Needed {
    param([string]$ModuleName) 
    if (Get-Module -ListAvailable -Name $ModuleName -Verbose:$false) {
        Write-Host "Module '$($ModuleName)' already exists, continue..." -ForegroundColor Green
    } 
    else {
        Write-Host "Module '$($ModuleName)' does not exist, installing..." -ForegroundColor Yellow
        Install-Module $ModuleName -Force  -AllowClobber -ErrorAction Stop
        Write-Host "Module '$($ModuleName)' installed." -ForegroundColor Green
    }
}

#! Install Az Accounts Module If Needed
Install-Module-If-Needed Az.Accounts

#! Install Az Compute Module If Needed
Install-Module-If-Needed Az.Compute

#! Install Az ConnectedMachine Module If Needed
Install-Module-If-Needed Az.ConnectedMachine

#! Check Azure Connection
Try { 
    Write-Verbose "Connecting to Azure Cloud..." 
    Connect-AzAccount -ErrorAction Stop -WarningAction SilentlyContinue | Out-Null 
}
Catch { 
    Write-Warning "Cannot connect to Azure Cloud. Please check your credentials. Exiting!" 
    Break 
}

$azSubs = Get-AzSubscription

foreach ( $azSub in $azSubs ) {
    $azSubName = $azSub.Name
    Write-Verbose "Set the Azure context to the subscription name: $($azSubName)"
    Set-AzContext -Subscription $azSub | Out-Null
    
    If ($Environment -eq "AzVM" -or $Environment -eq "Both") {
        # Handle AzVM (Azure Virtual Machines)
        $azVMs = Get-AzVM -ErrorAction SilentlyContinue        
        If ($azVMs) {
            Write-Verbose "Get the list of all Azure VMs that have AMA extension installed and Automatic Upgrade is NOT enabled..."
            $amas = @()
            $enabledAMA = @() # Array to hold VMs with automatic upgrade enabled
        
            foreach ($azVM in $azVMs) {        
                $amas += Get-AzVMExtension -VMName $azVM.Name -ResourceGroupName $azVM.ResourceGroupName | `
                    Where-Object { $_.Publisher -eq "Microsoft.Azure.Monitor" }

                # Check if automatic upgrade is enabled
                $enabledAMA += $amas | Where-Object { $_.EnableAutomaticUpgrade -eq $True }
            }

            If ($enabledAMA) {
                Write-Host "The following Azure VMs have Automatic Upgrade enabled for AMA:"
                $enabledAMA | ForEach-Object { Write-Host "$($_.VMName)" -ForegroundColor Green }
            } else {
                Write-Host "No Azure VMs have Automatic Upgrade enabled for AMA."
            }

            If ($amas) {
                Write-Verbose "Enabling Automatic Upgrade for VMs where it's not enabled..."
                foreach ($ama in $amas) {
                    If ($ama.EnableAutomaticUpgrade -eq $False) {
                        Write-Verbose "Enabling Automatic Upgrade for the Azure VM: $($ama.VMName)"
                        $ama | Set-AzVMExtension -EnableAutomaticUpgrade $True | Out-Null   
                    }
                }
            }
            else {
                Write-Verbose "All Azure VMs have Automatic Upgrade Extension enabled for AMA!"
            }
        }
        else {
            Write-Verbose "No Azure VMs found for the subscription name: $($azSubName)!"
        }   
    }

    If ($Environment -eq "AzArc" -or $Environment -eq "Both") {
        # Handle AzArc (Azure Arc Servers)
        $azArcServers = Get-AzConnectedMachine -ErrorAction SilentlyContinue
        If ($azArcServers) {
            Write-Verbose "Get the list of all Azure Arc Servers that have AMA extension installed and Automatic Upgrade is NOT enabled..."
            $amas = @()
            $enabledAMA = @() # Array to hold Arc Servers with automatic upgrade enabled
                
            foreach ($azVM in $azArcServers) {        
                $amas += Get-AzConnectedMachineExtension -MachineName $azVM.Name -ResourceGroupName $azVM.ResourceGroupName | `
                    Where-Object { $_.Publisher -eq "Microsoft.Azure.Monitor" }

                # Check if automatic upgrade is enabled
                $enabledAMA += $amas | Where-Object { $_.EnableAutomaticUpgrade -eq $True }
            }

            If ($enabledAMA) {
                Write-Host "The following Azure Arc Servers have Automatic Upgrade enabled for AMA:"
                $enabledAMA | ForEach-Object { Write-Host "$($_.MachineName)" -ForegroundColor Green }
            } else {
                Write-Host "No Azure Arc Servers have Automatic Upgrade enabled for AMA."
            }

            If ($amas) {
                Write-Verbose "Enabling Automatic Upgrade for Arc Servers where it's not enabled..."
                foreach ($ama in $amas) {
                    If ($ama.EnableAutomaticUpgrade -eq $False) {
                        $machineName = $ama.id.Split('/')[-3]
                        Write-Verbose "Enabling Automatic Upgrade for the Azure Arc Server: $($machineName)"
                        $ama | Update-AzConnectedMachineExtension -EnableAutomaticUpgrade | Out-Null          
                    }
                }
            }
            else {
                Write-Verbose "All Azure Arc Servers have Automatic Upgrade Extension enabled for AMA!"
            }
        }
        else {
            Write-Verbose "No Azure Arc Servers found for the subscription name: $($azSubName)!"
        }
    }
}
