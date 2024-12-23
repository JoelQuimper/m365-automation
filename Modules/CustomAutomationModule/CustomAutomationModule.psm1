<#
.SYNOPSIS
    Fonction de connexion à Microsoft Graph.

.DESCRIPTION
    Cette fonction permet de se connecter à Microsoft Graph en mode "application" et en utilisant les informations
    d'identification stockées dans Azure Key Vault.  Cette fonction est utilisée pour simplifier la connexion en 
    fonctionnant autant en mode interactif (dans VS Code pour "débugger", sur un serveur local...) que dans Azure Automation.

    Afin de se connecter en utilisant l'environnement, il est nécessaire de définir les variables suivantes:
    - KEYVAULT_NAME
    - KEYVAULT_SUBSCRIPTION_ID
    En mode interactif, simplement les ajouter comme variables d'environnement. En mode Azure Automation, elle doivent 
    être ajoutées dans les variables qui sont sous "Shared Resources".

    Le keyvault doit contenir les secrets suivants:
    - tenantId
    - clientId
    - clientSecret

.PARAMETER KeyVaultName
    Nom du Key Vault Azure contenant les secrets d'identification pour se connecter à Microsoft Graph.  Si non spécifié, 
    la fonction tentera de se connecter en utilisant des variables de l'environnement.

.PARAMETER SubscriptionId    
    ID de l'abonnement Azure contenant le Key Vault.  Si non spécifié, la fonction tentera de se connecter en utilisant 
    des variables de l'environnement.

.NOTES
    Auteur: Joël Quimper
    Date: 2024-12-02
#>
function Connect-GraphContext {
    param (
        [Parameter(Mandatory = $false)]
        [string]$KeyVaultName,

        [Parameter(Mandatory = $false)]
        [string]$SubscriptionId
    )

    # Get az connection to access to Azure Key Vault based if you are running in Azure Automation or locally
    try
    {
        if (-not $env:AZUREPS_HOST_ENVIRONMENT) {
            "Running Locally (Interactively)"
            if (-not $KeyVaultName) {
                "No KeyVaultName provided, checking environment variable." 
                $KeyVaultName = $env:KEYVAULT_NAME 
            }
            if (-not $SubscriptionId) {
                "No SubscriptionId provided, checking environment variable." 
                $SubscriptionId = $env:KEYVAULT_SUBSCRIPTION_ID 
            }
            
            # Exit if KeyVaultName or SubscritionId is null
            if (-not $KeyVaultName -or -not $SubscriptionId) {
                Write-Error -Message "KeyVaultName and SubscriptionId are required."
                throw "KeyVaultName and SubscriptionId are required."
            }

            az login
        } else {
            "Running in Azure Automation"
            if (-not $KeyVaultName) {
                "No KeyVaultName provided, checking automation shared settings variable." 
                $KeyVaultName = Get-AutomationVariable -Name KEYVAULT_NAME 
            }
            if (-not $SubscriptionId) {
                "No SubscriptionId provided, checking automation shared settings variable." 
                $SubscriptionId = Get-AutomationVariable -Name KEYVAULT_SUBSCRIPTION_ID 
            }

            # Exit if KeyVaultName or SubscritionId is null
            if (-not $KeyVaultName -or -not $SubscriptionId) {
                Write-Error -Message "KeyVaultName and SubscriptionId are required."
                throw "KeyVaultName and SubscriptionId are required."
            }

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
    Fonction de nettoyage de chaine de caracteres afin de pouvoir l'utiliser dans Entra.

.DESCRIPTION
    Cette fonction permet de nettoyer une chaine de caractères afin de pouvoir l'utiliser dans Entra.  Elle remplace les 
    caractères spéciaux par des tirets, met le tout en minuscule et s'assure qu'il n'y a pas de tirets en début ou en fin.
    Elle remplace aussi les caractères spéciaux français par leur équivalent anglais.

.PARAMETER GroupName
    Nom du groupe à netttoyer.

.NOTES
    Auteur: Joël Quimper
    Date: 2024-12-23
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

Export-ModuleMember -Function Connect-GraphContext, Set-EntraGroupName
