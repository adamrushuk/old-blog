<#
.SYNOPSIS
    Deploys a new Azure Static Website
.DESCRIPTION
    Deploys a new Azure Static Website using the following steps:
    - Creates a Resource group
    - Creates a Storage Account
    - Enables Static website on Storage Account (creates $web container)
    - Uploads website content to $web container
.NOTES
    Author:  Adam Rush
    Blog:    https://adamrushuk.github.io
    GitHub:  https://github.com/adamrushuk
    Twitter: @adamrushuk
#>

[CmdletBinding()]
param (
    $LocationName,
    $ResourceGroupName,
    $StorageAccountName,
    $ContentRelativePath = "content",
    $DomainFqdn,
    $StorageSkuName = "Standard_LRS",
    $StorageKind = "StorageV2",
    $StorageAccessTier = "Hot",
    $StaticWebsiteIndexDocument = "index.html",
    $StaticWebsiteErrorDocument404Path = "404.html",
    $Tags = @{ keep = "true" },
    $UseSubDomain = $false
)


#region Resource Group
$taskMessage = "Creating Resource Group: [$ResourceGroupName]"
Write-Host "`n$taskMessage..." -NoNewline

$rgParams = @{
    Name        = $ResourceGroupName
    Location    = $LocationName
    ErrorAction = "SilentlyContinue"
}
if (Get-AzResourceGroup @rgParams) {
    Write-Host "SKIPPING!" -ForegroundColor "Yellow"

} else {
    # Create resource group
    try {
        $azResourceGroupParams = @{
            Name        = $ResourceGroupName
            Location    = $LocationName
            Tag         = $Tags
            ErrorAction = "Stop"
            Verbose     = $VerbosePreference
        }
        New-AzResourceGroup @azResourceGroupParams | Out-String | Write-Verbose
    } catch {
        Write-Host "ERROR!" -ForegroundColor "Red"
        # Report error to Azure DevOps
        Write-Host "##vso[task.logissue type=error] $_"
        throw
    }
    Write-Host "SUCCESS!" -ForegroundColor "Green"
}
#endregion Resource Group


#region Storage Account
$taskMessage = "Creating Storage Account: [$StorageAccountName]"
Write-Host "`n$taskMessage..." -NoNewline

$saParams = @{
    Name              = $StorageAccountName
    ResourceGroupName = $ResourceGroupName
    ErrorAction       = "SilentlyContinue"
}
if (Get-AzStorageAccount @saParams) {
    Write-Host "SKIPPING!" -ForegroundColor "Yellow"

} else {
    # Create Storage Account
    try {
        $azStorageAccountParams = @{
            ResourceGroupName = $ResourceGroupName
            Location          = $LocationName
            Name              = $StorageAccountName
            SkuName           = $StorageSkuName
            Kind              = $StorageKind
            Tag               = $Tags
            ErrorAction       = "Stop"
            Verbose           = $VerbosePreference
        }
        New-AzStorageAccount @azStorageAccountParams | Out-String | Write-Verbose
    } catch {
        Write-Host "ERROR!" -ForegroundColor "Red"
        # Report error to Azure DevOps
        Write-Host "##vso[task.logissue type=error] $_"
        throw
    }
    Write-Host "SUCCESS!" -ForegroundColor "Green"
}
#endregion Storage Account


#region Enable Static Website
$taskMessage = "Enable Static Website for Storage Account: [$StorageAccountName]"
Write-Host "`n$taskMessage..." -NoNewline

try {
    # Set current Storage Account
    $saParams = @{
        Name              = $StorageAccountName
        ResourceGroupName = $ResourceGroupName
        ErrorAction       = "Stop"
    }
    Set-AzCurrentStorageAccount @saParams | Out-String | Write-Verbose

    ## Enable the static website feature for the selected storage account
    $enableStaticWebsiteParams = @{
        IndexDocument        = $StaticWebsiteIndexDocument
        ErrorDocument404Path = $StaticWebsiteErrorDocument404Path
        ErrorAction          = "Stop"
    }
    Enable-AzStorageStaticWebsite @enableStaticWebsiteParams | Out-String | Write-Verbose
} catch {
    Write-Host "ERROR!" -ForegroundColor "Red"
    # Report error to Azure DevOps
    Write-Host "##vso[task.logissue type=error] $_"
    throw
}
Write-Host "SUCCESS!" -ForegroundColor "Green"
#endregion Enable Static Website


#region Update Pipeline Variable
# Get Storage Account
$taskMessage = "Retrieving updated info for Storage Account: [$StorageAccountName]"
Write-Host "`n$taskMessage..." -NoNewline

try {
    $saParams = @{
        Name              = $StorageAccountName
        ResourceGroupName = $ResourceGroupName
        ErrorAction       = "Stop"
    }
    $updatedStorageAccount = Get-AzStorageAccount @saParams
} catch {
    Write-Host "ERROR!" -ForegroundColor "Red"
    # Report error to Azure DevOps
    Write-Host "##vso[task.logissue type=error] $_"
    throw
}
Write-Host "SUCCESS!" -ForegroundColor "Green"

# Update PRIMARY_ENDPOINT pipeline variable
[Uri]$primaryEndpoint = $updatedStorageAccount.PrimaryEndpoints.Web
$primaryEndpointHost = $primaryEndpoint.Host
$taskMessage = "Updating pipeline variable [PRIMARY_ENDPOINT] with value: [$primaryEndpointHost]..."
Write-Host "`n$taskMessage..." -NoNewline
Write-Host "##vso[task.setvariable variable=PRIMARY_ENDPOINT]$primaryEndpointHost"
Write-Host "SUCCESS!"
#region Update Pipeline Variable

#region Upload Static Website Content
# TODO enable content update
Write-Host "`nUploading content to `$web Container in Storage Account: [$StorageAccountName]" -NoNewline

# Get-ChildItem -Path $ContentRelativePath -Recurse | Set-AzStorageBlobContent -Container '$web'
Get-ChildItem -Path $ContentRelativePath/* -Include "index.html" |
    Set-AzStorageBlobContent -Container '$web' -ErrorAction "SilentlyContinue" | Out-Null
Write-Host "SUCCESS!"
#endregion Upload Static Website Content
