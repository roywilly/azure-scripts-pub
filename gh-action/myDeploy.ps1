param(
    [bool]$DRYRUN = $true
)

Write-Host "Starting deployment process..."
if ($DRYRUN) {
    Write-Host "Dry run mode enabled. No changes will be made."
} else {
    Write-Host "Executing deployment..."
}
