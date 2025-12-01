$ManagedIdentityId = "00000000-0000-0000-0000-000000000000" # Replace with your Managed Identity Object ID
$ApiAppId = "00000003-0000-0000-c000-000000000000" # Microsoft Graph
$PermissionValues = @("User.Read.All", "Group.Read.All") # Replace with the required permission values
$GraphBaseUrl = "https://graph.microsoft.com/v1.0"

# Assign an app role to a managed identity using Azure CLI and Microsoft Graph API
az login

# Get the service principal object for the target API and extract the object ID and app role ID
$url = "$($GraphBaseUrl)/servicePrincipals?`$filter=appId eq '$ApiAppId'"
$apiApp = (az rest --method GET --url $url | ConvertFrom-Json).value[0]
$apiEnterpriseAppId = $apiApp.id

# Assign the app roles to the managed identity
$assignUrl = "$($GraphBaseUrl)/servicePrincipals/$($ManagedIdentityId)/appRoleAssignments"
foreach ($PermissionValue in $PermissionValues) {
    $appRoleId = $apiApp.appRoles | Where-Object { $_.value -eq $PermissionValue -and $_.allowedMemberTypes -contains "Application" } | Select-Object -ExpandProperty id
    az rest --method POST --url $assignUrl --body "{'principalId': '$ManagedIdentityId','resourceId': '$apiEnterpriseAppId','appRoleId': '$appRoleId'}"
    "Assigned permission '$PermissionValue' to managed identity '$ManagedIdentityId'."
}