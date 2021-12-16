# From https://docs.microsoft.com/en-us/azure/governance/resource-graph/first-query-rest-api

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

# Get subscription id from az context
$mySubscriptionId = $azContext.Subscription

Write-Output "About to call REST API to get info on subscription with id $($mySubscriptionId)"
$restUri = "https://management.azure.com/subscriptions/$($mySubscriptionId)?api-version=2020-01-01"
$response = Invoke-RestMethod -Uri $restUri -Method Get -Headers $authHeader
Write-Output "Raw response: $($response)"
Write-Output "Response subscription displayname: $($response.displayName)"
Write-Output "Response subscription spendingLimit: $($response.subscriptionPolicies.spendingLimit)"
