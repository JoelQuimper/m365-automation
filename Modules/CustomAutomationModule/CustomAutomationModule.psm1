function Connect-GraphContext {
    param (
        [Parameter(Mandatory = $true)]
        [string]$KeyVaultName,

        [Parameter(Mandatory = $true)]
        [string]$ResourceGroupName,

        [Parameter(Mandatory = $true)]
        [string]$SubscriptionId
    )

    # Get az connection to access to Azure Key Vault based if you are running in Azure Automation or locally
    try
    {
        if (-not $env:AZUREPS_HOST_ENVIRONMENT) {
            "Running Locally (Interactively)"
            Connect-AzAccount
        } else {
            "Running in Azure Automation"
            Connect-AzAccount -Identity
        }

        # set default resource group
        Set-AzDefault -ResourceGroupName $ResourceGroupName

        # First check if Register-SecretVault AzKV is already registered
        $registeredVaults = Get-SecretVault
        if ($registeredVaults.Name -contains $KeyVaultName) {
            "$KeyVaultName vault is already registered."
        } else {
            "Registering $KeyVaultName vault."
            $VaultParameters = @{
                AZKVaultName = $KeyVaultName
                SubscriptionId = $SubscriptionId
            }
            Register-SecretVault -Module Az.KeyVault -Name $KeyVaultName -VaultParameters $VaultParameters
        }

        $tenantId = Get-Secret -Name tenantId -Vault $KeyVaultName -AsPlainText
        $clientId = Get-Secret -Name clientId -Vault $KeyVaultName -AsPlainText
        $SecuredPasswordPassword = Get-Secret -Name clientSecret -Vault $KeyVaultName -AsPlainText | ConvertTo-SecureString -AsPlainText -Force
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

Export-ModuleMember Connect-GraphContext
