# Azure powershell script to get role assignment using REST API
# https://docs.microsoft.com/en-us/rest/api/authorization/role-assignment-rest-sample

$azContext = Get-AzContext
if ($null -eq $azContext){
    Write-Output "You should have logged in to Azure first using Connect-AzAccount from the command line. Exiting."
    exit 
}
Write-Output "Writing azContext to show your current subscription:"
$azContext
Write-Output ""

Write-Output "About to get auth header"
$azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
$profileClient = New-Object -TypeName Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient -ArgumentList ($azProfile)
$token = $profileClient.AcquireAccessToken($azContext.Subscription.TenantId)
$authHeader = @{
    'Content-Type'='application/json'
    'Authorization'='Bearer ' + $token.AccessToken
}
Write-Output "Got auth header"

# The subscription to use: Using subscription id from current context
$subscriptionId = $azContext.Subscription.Id

# The user to get role assignment for: Object id of a user 
# (From Azure Active Directory, Users, someUser.objectId)
# REPLACE THIS ONE WITH ONE FROM YOUR TENANT:
$servicePrincipal = "00000000-0000-0000-0000-000000000000" 

$scope = "/subscriptions/$($subscriptionId)"
# Using role definition for 'Virtual Machine Contributor' (https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles)
$roleDefinitionId = "/subscriptions/$($subscriptionId)/providers/Microsoft.Authorization/roleDefinitions/9980e02c-c2be-4d73-94e8-173b1dc7cf3c" 
$uriFilter = "principalId eq '$servicePrincipal'"
$restUri = "https://management.azure.com/$scope/providers/Microsoft.Authorization/roleAssignments?" + '$filter=' + "$uriFilter&api-version=2020-04-01-preview" 
#https://management.azure.com/{scope}/providers/Microsoft.Authorization/roleAssignments?$filter={$filter}&api-version=2015-07-01
Write-Output "About to call REST API with uri $($restUri)"
$response = Invoke-Restmethod $restUri -Method "GET" -Headers $authHeader 
Write-Output "REST API call finished"

$exists = $false
$response.value | ForEach-Object {
    $existingRoleAssignment = $_
    if ($existingRoleAssignment.properties.roleDefinitionId -eq $roleDefinitionId) {
        Write-Output "Match on role assignment"
        $exists = $true
    }
}
Write-Output "Exists? $exists"
