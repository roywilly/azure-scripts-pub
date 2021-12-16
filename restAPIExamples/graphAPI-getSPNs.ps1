# Short example on how to call the Graph API

$azContext = Get-AzContext
if ($null -eq $azContext){
    Write-Output "You should have logged in to Azure first using Connect-AzAccount from the command line. Exiting."
    exit 
}
Write-Output "Writing azContext to show your current subscription:"
$azContext
Write-Output ""

# Get header that can be used for Graph API calls
$context = Get-AzContext
$graphToken = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, $context.Environment, $context.Tenant.Id.ToString(), $null, [Microsoft.Azure.Commands.Common.Authentication.ShowDialog]::Never, $null, "https://graph.microsoft.com").AccessToken
$Header = @{
    'Content-Type'  = 'application/json'
    'Authorization' = 'Bearer ' + $graphToken
}

# Applications (App Reg) https://docs.microsoft.com/en-us/graph/api/resources/application?view=graph-rest-1.0
# SPN (Enterpr Appl): https://docs.microsoft.com/en-us/graph/api/resources/serviceprincipal?view=graph-rest-1.0

# Get list of SPNs 
$uri = "https://graph.microsoft.com/v1.0/servicePrincipals/"
$Result =  Invoke-RestMethod -Headers $($Header) -Uri $Uri -UseBasicParsing -Method "get" -ContentType "application/json" 
#$Result.value[0].appDisplayName

Write-Output "Printing the first batch of SPNs"
foreach ($item in $Result.value) {
    Write-Output "$($item.displayName)"
}
