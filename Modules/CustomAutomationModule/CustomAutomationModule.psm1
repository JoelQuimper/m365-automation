<#
.SYNOPSIS
    Function to connect to Microsoft Graph.

.DESCRIPTION
    This function connects to Microsoft Graph in "application" mode using credentials stored in Azure Key Vault.
    This function simplifies the connection process by working both in interactive mode (in VS Code for debugging,
    on a local server, etc.) and in Azure Automation.

    The Key Vault must contain the following secrets:
    - tenantId
    - clientId
    - clientSecret

.PARAMETER KeyVaultName
    Name of the Azure Key Vault containing the identification secrets to connect to Microsoft Graph.

.PARAMETER SubscriptionId    
    ID of the Azure subscription containing the Key Vault.
#>
function Connect-GraphContextFromKeyVault {
    param (
        [Parameter(Mandatory = $true)]
        [string]$KeyVaultName,

        [Parameter(Mandatory = $true)]
        [string]$SubscriptionId
    )

    # Get az connection to access to Azure Key Vault based if you are running in Azure Automation or locally
    try
    {
        if (-not $env:AZUREPS_HOST_ENVIRONMENT) {
            "Running Locally (Interactively)"
            az login
        } else {
            "Running in Azure Automation"
            az login --identity
        }

        az account set --subscription $SubscriptionId

        $tenantId = az keyvault secret show --name tenantId --vault-name $KeyVaultName --query value -o tsv
        $clientId = az keyvault secret show --name clientId --vault-name $KeyVaultName --query value -o tsv
        $SecuredPasswordPassword = az keyvault secret show --name clientSecret --vault-name $KeyVaultName --query value -o tsv | ConvertTo-SecureString -AsPlainText -Force
        $ClientSecretCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $clientId, $SecuredPasswordPassword

        # Connect to Microsoft Graph
        "Connecting to graph with clientId: " + $clientId + " and tenantId: " + $tenantId
        return Connect-MgGraph -TenantId $TenantId -ClientSecretCredential $ClientSecretCredential
    }
    catch {
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

<#
.SYNOPSIS
    Function to connect to Microsoft Graph.

.DESCRIPTION
    This function connects to Microsoft Graph either in interactive mode (locally) or in Azure Automation
    using Managed Identity. When using it in Azure Automation, the required scopes must be assigned to the Managed Identity in Entra.  
    When running locally, it will prompt for interactive login. The required scopes must be previously granted by an administrator.
    Since I am using the interactive mode only on my development tenant, I usually manually do a Connect-MgGraph with my required scopes
    and grant admin consent prior to running this function.
#>
function Connect-GraphContext {
    param (
    )
    try {
        if (-not $env:AZUREPS_HOST_ENVIRONMENT) {
            "Running Locally (Interactively)"
            return Connect-MgGraph
        } else {
            "Running in Azure Automation"
            az login --identity --allow-no-subscriptions
            $token = az account get-access-token --resource-type ms-graph | ConvertFrom-Json
            $secureStringToken = ConvertTo-SecureString -String $token.accessToken -AsPlainText -Force
            return Connect-MgGraph -AccessToken $secureStringToken
        }
    }
    catch {
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

<#
.SYNOPSIS
    Function to clean a string to make it usable in Entra.

.DESCRIPTION
    This function cleans a string to make it usable in Entra. It replaces special characters with hyphens,
    converts everything to lowercase, and ensures there are no hyphens at the beginning or end.
    It also replaces French special characters with their English equivalents.

.PARAMETER GroupName
    Name of the group to clean.
#>
function Set-EntraGroupName {
    param (
        [Parameter(Mandatory = $true)]
        [string]$GroupName
    )

    # Convert the name to lowercase
    $GroupName = $GroupName.ToLower()

    # Replace French special characters with their English equivalent
    $GroupName = $GroupName -replace 'é|è|ê|ë', 'e'
    $GroupName = $GroupName -replace 'à|â|ä', 'a'
    $GroupName = $GroupName -replace 'ù|û|ü', 'u'
    $GroupName = $GroupName -replace 'ç', 'c'
    $GroupName = $GroupName -replace 'ô|ö', 'o'
    $GroupName = $GroupName -replace 'î|ï', 'i'
    $GroupName = $GroupName -replace 'ÿ', 'y'
    $GroupName = $GroupName -replace 'œ', 'oe'
    $GroupName = $GroupName -replace 'æ', 'ae'

    # Replace invalid characters with an an hyphen
    $escapedName = $GroupName -replace '[^a-zA-Z0-9-]', '-'

    # Ensure the name does not start or end with a hyphen
    $escapedName = $escapedName.Trim('-')

    # Replace multiple hyphens with a single hyphen
    $escapedName = $escapedName -replace '--+', '-'

    # Return the escaped name
    return $escapedName
}

Export-ModuleMember -Function Connect-GraphContextFromKeyVault,Connect-GraphContext, Set-EntraGroupName
