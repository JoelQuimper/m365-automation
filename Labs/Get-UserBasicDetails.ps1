param (
    [Parameter(Mandatory = $true)]
    [string]$UserEmailAddress
)

"Getting basic details for user with email address: $UserEmailAddress"
try {
    $clientId = "<YOUR_CLIENT_ID>"
    $tenantId = "<YOUR_TENANT_ID>"
    $clientSecret = "<YOUR_CLIENT_SECRET>" | ConvertTo-SecureString -AsPlainText -Force
    $ClientSecretCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $clientId, $clientSecret
    Connect-MgGraph -TenantId $tenantId -ClientSecretCredential $ClientSecretCredential

    $user = Get-MgUser -UserId $UserEmailAddress -Property "DisplayName,Id,UserPrincipalName,Mail,JobTitle,Department,AccountEnabled"
    "User Details:"
    " - User ID: $($user.Id)"
    " - Display Name: $($user.DisplayName)"
    " - User Principal Name: $($user.UserPrincipalName)"
    " - Email: $($user.Mail)"
} catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}