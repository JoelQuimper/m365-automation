param (
    [Parameter(Mandatory = $true)]
    [string]$TeamName,

    [Parameter(Mandatory = $true)]
    [string]$TeamDescription,

    [Parameter(Mandatory = $true)]
    [array]$TeamOwners,

    [Parameter(Mandatory = $false)]
    [string]$TeamTemplateName = "DEFAULT"
)

"Creating team $TeamName with description $TeamDescription and template $TeamTemplateName"
foreach ($owner in $TeamOwners) {
    "Owner: $owner"
}

# Load the function to connect to Microsoft Graph and manage environment
. "./Create-GraphConnectionFunction.ps1"

Connect-GraphContext -KeyVaultName "kv-m365admin-jq" -SubscriptionId "e79c36e6-8354-4130-a60b-694835221fef"
$groups = Get-MgGroup
foreach ($group in $groups) {
    "group - $($group.DisplayName)"
}

