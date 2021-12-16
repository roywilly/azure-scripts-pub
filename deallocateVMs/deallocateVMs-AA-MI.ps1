# Deallocate (Stop) VMs not having tag value containing 'Prod' or 'AlwaysOn'.
# Running in an Azure Automation Account (AA) using the AA Managed Identity (MI).
# - MI means there are no passwords, certificates etc to maintain.
# - MI simplifies the code. 
# - MI is more secure. 

# Create a new AA or update an existing AA:
#  - enable 'System assigned' managed identity
#  - and say no to RunAsAccount
# After creation, you will find the MI under Azure Active Directory, Enterprise Applications.
#
# As Owner, give the MI 'Virtual Machine Contributor' to either the full subscription or to a Resource Group
#
# Create a new Runbook in the AA: 
# - Runbook type: Powershell
# - Runtime version: 7.1 (preview)
# 
# Connect the Runbook to a Schedule of your choice

Import-Module 'az.accounts'
Import-Module 'az.compute'

Write-Output "Starting"

# Print module versions
Get-Module az.accounts
Get-Module az.compute

# Connect and run script with the AA MI
Connect-azAccount -Identity

# Get all the VMs 
$allVMs = Get-AzVM
if ($allVMs -eq $null) {
    Write-Output "Found no VMs: nothing to shutdown. Exiting."
    return
}

# Get the list of VMs to keep alive, based on the VMs Tag VALUES (not Tag Names)
$keepAliveVMs = Get-AzVM | where {$_.Tags.Values -like 'Prod*' -or $_.Tags.Values -like 'AlwaysOn'}
if ($keepAliveVMs -eq $null) {
    Write-Output "There are no VMs to keep alive: shutting down all VMs"
    $shutdownVMs = $allVMs 
} else {
    # Diff the 2 lists of VMs 
    $shutdownVMs = Compare-Object -ReferenceObject $keepAliveVMs -DifferenceObject $allVMs -Property Name -PassThru
}

foreach ($vm in $shutdownVMs) {
    Stop-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Force -AsJob
    Write-Output "VM $($vm.Name) in RG $($vm.ResourceGroupName) being turned off"
}

Write-Output "Finished"
