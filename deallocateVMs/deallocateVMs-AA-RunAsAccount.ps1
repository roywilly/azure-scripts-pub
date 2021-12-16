# THIS SCRIPT IS OUTDATED: RunAsAccount is not the best way any longer

# Script to shutdown all VMs in the subscription that 
# does not have a TagValue starting with either 'Prod' or 'AlwaysOn'. 
# Purpose: deallocate all DEV and TEST Virtual Machines in the subscription. 
# Pre-requisite: existing Automation RunAs Account with the proper access 
# rights on subscription or RG level (Contributor but optimally 
# Virtual Machine Contributor only).   
# 
# Note that the code uses the 'old' syntax (AzureRMVM instead of just AzVM) 
# This means as of early 2020 you can run the code as is in a fresh Automation Account.
# If you want to use the newer AzVM syntax, you must update the AutomationAccount 
# Powershell modules and add import-module Az.Compute in this script and of course 
# replace all AzureRM strings with Az. 

# The script below contains 2 parts: 
# The top part is necessary to authenticate as the RunAsAccount and can be re-uused in other scripts. 
# The last part is reading VM information and then shutting down VMs without the Prod* or AlwaysOn tag values.

Write-Output "Starting script";

$connectionName = "AzureRunAsConnection"
try
{
    # Get the automation connection 
    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName; 

    $msg = "ConnectionName: " + $connectionName + " with TenantID: " + $servicePrincipalConnection.TenantID;
    Write-Output $msg;

    "Logging in to Azure using ServicePrincipal ..."
    Add-AzureRmAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
}
catch {
    if (!$servicePrincipalConnection)
    {
        $ErrorMessage = "Connection $connectionName not found..."
        throw $ErrorMessage
    } else {
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}



# Get all the VMs in the subscription
$allVMs = Get-AzureRMVM;
if ($allVMs -eq $null) {
    $msg = "There are no VMs in this subscription: nothing to shutdown. Exiting. ";
    Write-Output $msg;
    return;
}

# Get the list of VMs to keep alive, based on the VMs Tag VALUES (not Tag Names)
$keepAliveVMs = Get-AzureRMVM | where {$_.Tags.Values -like 'Prod*' -or $_.Tags.Values -like 'AlwaysOn'};
if ($keepAliveVMs -eq $null) {
    $msg = "There are no VMs to keep alive; shutting down all VMs";
    Write-Output $msg;
    $shutdownVMs = $allVMs; 
} else {
    # Diff the 2 lists of VMs 
    $shutdownVMs = Compare-Object -ReferenceObject $keepAliveVMs -DifferenceObject $allVMs -Property Name -PassThru;
}

foreach ($vm in $shutdownVMs) {
    Stop-AzureRMVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Force -AsJob;
    $msg = $vm.Name + "  " + $vm.ResourceGroupName + "   Finished turning VM off";
    Write-Output $msg;
}

Write-Output "The End";
