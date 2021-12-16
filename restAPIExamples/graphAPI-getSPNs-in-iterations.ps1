# Short example on how to call the Graph API repeatedly for data larger 
# than MS returns in one call. The first call returns a link to the next 
# batch of data (NextLink) and so on. 

$azContext = Get-AzContext
if ($null -eq $azContext){
    Write-Output "You should have logged in to Azure first using Connect-AzAccount from the command line. Exiting."
    exit 
}
Write-Output "Writing azContext to show your current subscription:"
$azContext
Write-Output ""
$ErrorActionPreference = "Stop"

# Get header that can be used for Graph API calls
$context = Get-AzContext
$graphToken = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, $context.Environment, $context.Tenant.Id.ToString(), $null, [Microsoft.Azure.Commands.Common.Authentication.ShowDialog]::Never, $null, "https://graph.microsoft.com").AccessToken
$Header = @{
    'Content-Type'  = 'application/json'
    'Authorization' = 'Bearer ' + $graphToken
}

# Applications (App Reg) https://docs.microsoft.com/en-us/graph/api/resources/application?view=graph-rest-1.0
# SPN (Enterpr Appl): https://docs.microsoft.com/en-us/graph/api/resources/serviceprincipal?view=graph-rest-1.0

# Note that MS have inconsistent use of the terms id, appid, objectid, etc

$appRegUri = "https://graph.microsoft.com/v1.0/applications/"

$loopCounter = 0

# Set to 3 or so when debugging to avoid looping through all the data 
$maxLoops = 3

# Clean the output file:
"" | Set-Content -Path "./outputfile.csv" 

while (($loopCounter -lt $maxLoops) -and ($null -ne $appRegUri) -and ("" -ne $appRegUri)) {
    Write-Output "Loop $($loopCounter) using appRegUri  $($appRegUri)"

    $appRegResult = Invoke-RestMethod -Headers $($Header) -uri $appRegUri -UseBasicParsing -Method "get" -ContentType "application/json" 

    # Save the Uri for next call for getting next batch/page of Applications so we have it for next loop
    $appRegUri = $appRegResult.'@Odata.NextLink'

    # New Rest API call to read all Owners of this Application
    # Then concatenate all owners of the AppReg and print to output file
    foreach ($appReg in $appRegResult.value) {
        #$appReg.DisplayName
        #$appReg.id
        $appRegOwnerUri = "https://graph.microsoft.com/v1.0/applications/$($appReg.id)/owners"
        #Write-Output "      appRegOwnerUri  $($appRegOwnerUri)"
        $ownersResult = Invoke-RestMethod -Headers $($Header) -uri $appRegOwnerUri -UseBasicParsing -Method "get" -ContentType "application/json" 
        $concatOwners = ""
        foreach ($owner in $ownersResult) {
            #$ownersResult.value.mail
            $concatOwners = $concatOwners + " " + $ownersResult.value.mail
        }

        #appReg.id = appReg.objectId 
        #appReg.appid = appReg.Application(client)ID
        #Write-Output "$($appReg.DisplayName), $($appReg.id), $($appReg.appid), $($concatOwners)"
        Add-Content -Path "./outputfile.csv" -value "$($appReg.DisplayName), $($appReg.id), $($appReg.appid), $($concatOwners)"
    }

    $loopCounter++
}
