<#
.SYNOPSIS
    Intentional import of PowerShell modules.

.DESCRIPTION
    This script is used only when in development mode.

    Since modules can vary across deployments and environments, 
    I prefer to import and load them manually, similar to using 
    NuGet packages in C#. This ensures that the necessary modules are 
    explicitly declared and imported, reducing the risk of conflicts or 
    missing dependencies.

    ** Modules must be saved locally beforehand using Save-Module.
#>
# Define environment variables for the key vault
$env:KEYVAULT_NAME= "kv-m365admin-jq"
$env:KEYVAULT_SUBSCRIPTION_ID= "e79c36e6-8354-4130-a60b-694835221fef"

# Import Microsoft Graph modules
$graphVersion = "2.32.0"
$graphPowerShellModulePath = "C:\src\PowerShellModules\Microsoft.Graph\$graphVersion"
$graphAuthenticationPowerShellModule = "$graphPowerShellModulePath\Microsoft.Graph.Authentication\$graphVersion\Microsoft.Graph.Authentication.psd1"
$graphPowerShellModule = "$graphPowerShellModulePath\Microsoft.Graph\$graphVersion\Microsoft.Graph.psd1"

$allGraphModules = Get-ChildItem -Path $graphPowerShellModulePath -Recurse -Filter *.psd1
$totalModulesCount = $allGraphModules.Count
"Importing Microsoft.Graph, there are $totalModulesCount modules to import."

# This module must be loaded first to avoid dependency errors.
"Importing module (1 / $totalModulesCount): $graphAuthenticationPowerShellModule"
Import-Module $graphAuthenticationPowerShellModule

$filteredGraphModules = $allGraphModules | Where-Object { $_.FullName -notlike "*Microsoft.Graph.Authentication.psd1*" } | Where-Object { $_.FullName -notlike "*Microsoft.Graph.psd1*" }
for ($i = 0; $i -lt $filteredGraphModules.Count; $i++) {
    $module = $filteredGraphModules[$i]
    "Importing module ($($i+2) / $totalModulesCount): $($module.FullName)"
    Import-Module $module.FullName
}

# This module must be loaded last.
"Importing module ($totalModulesCount / $totalModulesCount): $graphPowerShellModule"
Import-Module $graphPowerShellModule

# Import the "CustomAutomationModule" module containing our reusable PowerShell functions.
"Importing module: CustomAutomationModule"
Import-Module ./CustomAutomationModule
