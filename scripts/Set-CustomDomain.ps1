<#
.SYNOPSIS
    Configures a Custom Domain for an Azure Static Website
.DESCRIPTION
    Configures a Custom Domain for an Azure Static Website, and selects CNAME validation method
.NOTES
    Author:  Adam Rush
    Blog:    https://adamrushuk.github.io
    GitHub:  https://github.com/adamrushuk
    Twitter: @adamrushuk
#>

[CmdletBinding()]
param (
    $ResourceGroupName,
    $StorageAccountName,
    $DomainFqdn,
    $UseSubDomain = $false
)


#region Custom Domain
$taskMessage = "Setting Custom Domain: [$DomainFqdn]"
Write-Host "`n$taskMessage..." -NoNewline

try {
    # Set Custom Domain
    # UseSubDomain enables indirect CNAME validation
    $setAzSaParams = @{
        Name              = $StorageAccountName
        ResourceGroupName = $ResourceGroupName
        CustomDomainName  = $DomainFqdn
        UseSubDomain      = $UseSubDomain
        ErrorAction       = "Stop"
    }
    Set-AzStorageAccount @setAzSaParams | Out-String | Write-Verbose
} catch {
    Write-Host "ERROR!" -ForegroundColor "Red"
    # Report error to Azure DevOps
    Write-Host "##vso[task.logissue type=error] $_"
    throw
}
Write-Host "SUCCESS!" -ForegroundColor "Green"
#endregion Custom Domain
