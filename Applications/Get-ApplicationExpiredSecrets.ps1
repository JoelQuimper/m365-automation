param (
    [Parameter(Mandatory = $false)]
    [string]$ApplicationId,
    [Parameter(Mandatory = $false)]
    [int]$ExpiresInDays = 30
)

"Getting secrets that will expire in less then $ExpireInDays days for application(s)"
try {
    # Connect to Graph using custom module
    Connect-GraphContext

    $applicationsToScan = New-Object System.Collections.ArrayList
    if ($ApplicationId) {
        "Getting expired secrets for application $ApplicationId"
        $application = Get-MgApplication -ApplicationId $ApplicationId
        $applicationsToScan += $application
    } else {
        "Getting expired secrets for all applications"
        $applicationsToScan = Get-MgApplication
        "Found $($applicationsToScan.Count) applications"
    }

    foreach ($application in $applicationsToScan) {
        "### Getting secrets for application $($application.DisplayName)"
        $secrets = $application.PasswordCredentials
        "It has $($secrets.Count) secrets"
        foreach ($secret in $secrets) {
            if($secret.EndDateTime -lt (Get-Date)) {
                "Secret $($secret.DisplayName) is already expired since $($secret.EndDateTime)"
                ## should decide on action to take
            }
            elseif($secret.EndDateTime -lt (Get-Date).AddDays($ExpiresInDays)) {
                "Secret $($secret.DisplayName) will expire on $($secret.EndDateTime)"
                ## should decide on action to take
            }
        }
    }

} catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}