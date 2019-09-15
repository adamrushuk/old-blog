<#
.SYNOPSIS
    Updates a DNS record with a new value
.DESCRIPTION
    Updates a DNS record with a new value using the GoDaddy PowerShell module
.LINK
    https://www.powershellgallery.com/packages/Trackyon.GoDaddy
.NOTES
    Author:  Adam Rush
    Blog:    https://adamrushuk.github.io
    GitHub:  https://github.com/adamrushuk
    Twitter: @adamrushuk
#>

[CmdletBinding()]
param (
    [ValidateNotNullOrEmpty()]
    [String]$DomainName,

    [ValidateNotNullOrEmpty()]
    [ValidateSet("A", "CNAME")]
    [String]$RecordType,

    [ValidateNotNullOrEmpty()]
    [String]$RecordName,

    [ValidateNotNullOrEmpty()]
    [String]$RecordValue,

    [ValidateNotNullOrEmpty()]
    [String]$ApiKey,

    [ValidateNotNullOrEmpty()]
    [String]$ApiSecret,

    [ValidateNotNullOrEmpty()]
    [Int]$Ttl = 600
)


# Init
Install-Module -Name "Trackyon.GoDaddy"-Scope "CurrentUser" -Force
$apiCredential = [pscredential]::new($ApiKey, (ConvertTo-SecureString -String $ApiSecret -AsPlainText -Force))

# Output Domain
Get-GDDomain -credentials $apiCredential -domain $DomainName | Out-String | Write-Output

# Output current records
Get-GDDomainRecord -credentials $apiCredential -domain $DomainName | Out-String | Write-Output

# Update A record
Write-Output "STARTED: $Updating domain [$DomainName] [$RecordType] record [$RecordName] with value [$RecordValue]"
Set-GDDomainRecord -credentials $apiCredential -domain $DomainName -name $RecordName -ipaddress $RecordValue -type "CNAME" -ttl $Ttl -Force
Write-Output "FINISHED: Updating DNS record."

# Output updated records
Get-GDDomainRecord -credentials $apiCredential -domain $DomainName | Out-String | Write-Output
