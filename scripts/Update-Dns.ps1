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
    [Int]$Ttl = 600,

    [Switch]$Wait,

    [Int]$TimeoutSeconds = 1800, # 1800s = 30 mins

    [Int]$RetryIntervalSeconds = 10
)


#region DNS Update
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
#endregion DNS Update


#region Wait for DNS propagation
# ! Assumes running on a Linux Agent
# TODO: could change logic to just wait for successful response (200) if DNS cache issues
$timer = [Diagnostics.Stopwatch]::StartNew()

# Construct lookup command
$lookupCommand = switch ($RecordType) {
    "CNAME" { "dig $($RecordName).$($DomainName) $RecordType +short" }
    Default { }
}

# Enter loop
while ($currentValue = Invoke-Expression $lookupCommand) {

    if ($timer.Elapsed.TotalSeconds -gt $TimeoutSeconds) {
        Write-Output "##vso[task.logissue type=error]Elapsed task time of [$($timer.Elapsed.TotalSeconds)] has exceeded timeout of [$TimeoutSeconds]"
        exit 1
    } else {

        Write-Output "Current [$RecordType] record [$RecordName] value: [$RecordValue]"

        if ($currentValue -match $RecordValue) {
            Write-Output "FINISHED: Waiting for DNS propagation."
            break
        } else {
            Write-Output "##vso[task.logissue type=warning]Still waiting for DNS propagation... [$($timer.Elapsed.Minutes)m$($timer.Elapsed.Seconds)s elapsed]"
            Start-Sleep -Seconds $RetryIntervalSeconds
        }
    }
}

$timer.Stop()
Write-Output "DNS propagation complete after [$($timer.Elapsed.Minutes)m$($timer.Elapsed.Seconds)s]"
#endregion Wait for DNS propagation
