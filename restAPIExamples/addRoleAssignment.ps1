# Azure powershell script to add role assignment using REST API
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

# The subscription to add role assignment to: Using subscription id from current context
$subscriptionId = $azContext.Subscription.Id

# The user to add role assignment for: Object id of a user 
# (From Azure Active Directory, Users, someUser.objectId)
# REPLACE THIS ONE WITH ONE FROM YOUR TENANT:
$servicePrincipal = "74366248-e1f4-43a6-915f-bd33e36bbc43" 

$scope = "/subscriptions/$($subscriptionId)"
$roleAssignmentID = (New-Guid).Guid
# Using role definition for 'Virtual Machine Contributor' (https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles)
$roleDefinitionId = "/subscriptions/$($subscriptionId)/providers/Microsoft.Authorization/roleDefinitions/9980e02c-c2be-4d73-94e8-173b1dc7cf3c" 
$restUri = "https://management.azure.com{0}/providers/Microsoft.Authorization/roleAssignments/{1}?api-version=2020-04-01-preview" -f $scope, $roleAssignmentID
$body = @{
    properties = @{
        roledefinitionId = $roleDefinitionId
        principalId      = $servicePrincipal
        description      = "The description here"
    }
} | convertto-json
Write-Output "About to call REST API with uri $($restUri) and body $($body)"
$response = Invoke-WebRequest $restUri -Method "PUT" -Headers $authHeader -Body $body
Write-Output "Raw response: $($response)"
