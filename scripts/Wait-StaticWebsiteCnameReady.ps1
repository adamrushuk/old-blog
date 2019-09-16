<#
.SYNOPSIS
    Wait for CNAME DNS record to propagate, so Azure Static Website can start CNAME validation
.DESCRIPTION
    Wait for CNAME DNS record to propagate, so Azure Static Website can start CNAME validation.
    When the CNAME DNS record directs traffic to an Azure Static Website WITHOUT a Custom Domain entry, Azure
    returns StatusCode is 400. Only after this point can you define a Custom Domain using CNAME validation.
.NOTES
    Author:  Adam Rush
    Blog:    https://adamrushuk.github.io
    GitHub:  https://github.com/adamrushuk
    Twitter: @adamrushuk
#>

[CmdletBinding()]
param (
    [ValidateNotNullOrEmpty()]
    [String]$DomainFqdn,

    [Int]$WaitForStatusCode = 400,

    [Int]$TimeoutSeconds = 1800, # 1800s = 30 mins

    [Int]$RetryIntervalSeconds = 30
)

$timer = [Diagnostics.Stopwatch]::StartNew()

# Start loop
while ($true) {
    if ($timer.Elapsed.TotalSeconds -gt $TimeoutSeconds) {
        Write-Output "##vso[task.logissue type=error] Elapsed task time of [$($timer.Elapsed.TotalSeconds)] seconds has exceeded timeout of [$TimeoutSeconds] seconds"
        exit 1

    } else {
        try {
            $response = Invoke-WebRequest -Uri $DOMAIN_FQDN
        } catch {
            $response = $_.Exception.Response
        }

        # Wait until StatusCode
        $statusCode = $response.StatusCode.value__
        Write-Output "Current Web Response status code: [$statusCode]"
        if ($statusCode -eq $WaitForStatusCode) {
            Write-Output "CNAME entry should now exist, as StatusCode [$statusCode] matches WaitForStatusCode [$WaitForStatusCode]"
            break
        }

        Write-Output "##vso[task.logissue type=warning] Still waiting for CNAME to propagate... [$($timer.Elapsed.Minutes)m$($timer.Elapsed.Seconds)s elapsed]"
        Start-Sleep -Seconds $RetryIntervalSeconds
    }
}

$timer.Stop()
Write-Output "Wait complete after [$($timer.Elapsed.Minutes)m$($timer.Elapsed.Seconds)s]"
