<#
.SYNOPSIS
    Importation intentionnelle des modules PowerShell.

.DESCRIPTION
    Ce script est utilisé uniquement lorsque on est en mode développement.

    Comme les modules peuvent varier selon les déploiements et les environnements, 
    je préfère les importer et charger de manière manuelle, similaire à l'utilisation 
    des packages NuGet en C#. Cela permet de s'assurer que les modules nécessaires sont 
    explicitement déclarés et importés, réduisant ainsi les risques de conflits ou de 
    dépendances manquantes.

    ** Les modules doivent être sauvergardé dans le répertoire "Modules" au préalable.

.NOTES
    Auteur: Joël Quimper
    Date: 2024-12-02
#>

# Ce module doit être chargé en premier pour éviter les erreurs de dépendances.
Import-Module .\Graph\Microsoft.Graph.Authentication\2.25.0\Microsoft.Graph.Authentication.psd1

$allGraphModules = Get-ChildItem -Path .\Graph\ -Recurse -Filter *.psd1
$filteredGraphModules = $allGraphModules | Where-Object { $_.FullName -notlike "*Microsoft.Graph.Authentication.psd1*" } | Where-Object { $_.FullName -notlike "*Microsoft.Graph.psd1*" }

Write-Output "There are $($filteredGraphModules.Count) modules to import."

foreach ($module in $filteredGraphModules) {
    Write-Output "Importing module: $($module.FullName)"
    Import-Module $module.FullName
}

# Ce module doit être chargé en dernier.
Import-Module .\Graph\Microsoft.Graph\2.25.0\Microsoft.Graph.psd1
