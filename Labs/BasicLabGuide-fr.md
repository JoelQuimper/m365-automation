## Guide de laboratoire
Bienvenue dans ce laboratoire d'automatisation simple ! Ce document vous aidera à naviguer à travers un laboratoire simple conçu pour améliorer votre expérience d'apprentissage. Suivez les instructions ci-dessous pour commencer.

Le laboratoire est construit de manière à ce qu'un utilisateur puisse demander à voir ses informations de profil depuis Entra en utilisant l'API Microsoft Graph et PowerShell en remplissant simplement un formulaire dans SharePoint.

### Commencer
1. **Configurez votre environnement** : Assurez-vous d'avoir tous les logiciels et outils nécessaires installés.
    - Installez PowerShell 7.5 [Installing PowerShell on Windows - PowerShell | Microsoft Learn](https://learn.microsoft.com/fr-fr/powershell/scripting/install/installing-powershell-core-on-windows)
    - Installez le SDK PowerShell Microsoft Graph [Install the Microsoft Graph PowerShell SDK - Microsoft Graph | Microsoft Learn](https://learn.microsoft.com/fr-fr/powershell/microsoftgraph/installation?view=graph-powershell-1.0)
    - Installez Visual Studio Code [Download Visual Studio Code - Mac, Linux, Windows](https://code.visualstudio.com/)
    - Ajoutez l'extension PowerShell à Visual Studio Code [PowerShell Extension for Visual Studio Code - PowerShell | Microsoft Learn](https://code.visualstudio.com/docs/languages/powershell)
    - Installez Azure CLI [How to install the Azure CLI | Microsoft Learn](https://learn.microsoft.com/fr-fr/cli/azure/install-azure-cli)
    - Idéalement un abonnement Visual Studio, qui inclut un locataire de test ainsi que des crédits Azure mensuels.

2. **Créez l'inscription d'application** : Suivez les étapes ci-dessous pour créer une inscription d'application dans Azure AD.
    - Dans le centre d'administration Entra, naviguez vers « Inscriptions d'applications »
    - Cliquez sur « Nouvelle inscription »
    - Nommez votre application (par exemple, « LabGraphApp »). Conservez les paramètres par défaut pour les types de comptes pris en charge et l'URI de redirection.
    - Définissez les autorisations d'API pour inclure « User.ReadBasic.All » sous Microsoft Graph avec le consentement administrateur. (il doit s'agir d'une autorisation d'application, pas déléguée)
    ![API Permissions](images/api-permission.png)
    - Créez un secret client et notez l'ID d'application (client), l'ID de répertoire (locataire) et la valeur du secret client.
    - **AVERTISSEMENT** : Si vous effectuez ce laboratoire sur votre locataire de production, assurez-vous d'utiliser et de stocker le secret client de manière sécurisée, car il fournit un accès pour lire tous vos utilisateurs.

3. **Configurez la liste SharePoint** : Créez une liste SharePoint pour capturer les demandes des utilisateurs.
    - Créez un nouveau site SharePoint ou utilisez-en un existant.
    - Créez une nouvelle liste nommée « UserProfileRequests ».
    ![new-list](images/new-list.png)
    - Ajoutez les colonnes suivantes :
        - User (Personne)
        - RequestStatus (Choix : Pending, Completed)
        - ProfileInfo (Plusieurs lignes de texte)
    - Cela devrait ressembler à ceci
    ![new-list-2](images/new-list-2.png)

4. **Créez et testez le script PowerShell** : Créez le script PowerShell qui interagira avec l'API Microsoft Graph pour récupérer les informations de profil utilisateur.
    - Clonez ce référentiel sur votre machine locale.
    - Ouvrez le référentiel cloné dans Visual Studio Code.
    - Trouvez le fichier « Get-UserBasicDetails.ps1 » et ouvrez-le.
    ![code](images/code.png)
    - Mettez à jour le script avec les détails de votre inscription d'application (ID client, ID de locataire, secret client).
    **IMPORTANT** : nous mettons le secret client en texte brut par simplicité dans ce laboratoire. Vous ne devriez jamais faire cela dans la vraie vie. Vous devriez envisager d'utiliser Azure Key Vault pour gérer les secrets. Des exemples sont disponibles dans ce référentiel.
    - Enregistrez le script.
    - Testez le script localement pour vous assurer qu'il fonctionne comme prévu. Vous pouvez le faire en exécutant le script dans Visual Studio Code ou le terminal PowerShell. Assurez-vous qu'il récupère correctement les informations de profil utilisateur.
    ![pwsh-result](images/pwsh-result.png)
    
5. **Créez un compte Azure Automation** : Créez un compte Azure Automation pour héberger et exécuter le script PowerShell.
    - Dans le portail Azure, [naviguez vers les groupes de ressources](https://portal.azure.com/#browse/resourcegroups) et créez un nouveau groupe de ressources (par exemple, « rg-automation-workshop »).
    ![create-rg](images/create-rg.png)
    **AVERTISSEMENT** encore une fois, si vous effectuez ceci sur votre locataire de production, assurez-vous de le créer de manière sécurisée.
    - Naviguez vers le groupe de ressources nouvellement créé.
    - Dans le groupe de ressources, créez un nouveau compte Automation.
    ![create-aa](images/create-aa.png)
    - Nommez le compte Automation (par exemple, « aa-automation-workshop »), sélectionnez la région appropriée et créez-le avec le reste des paramètres par défaut.
    ![create-aa-2](images/create-aa-2.png)
    - Dans le compte Automation, naviguez vers « Environnements d'exécution » et créez un nouvel environnement d'exécution PowerShell 7.4 (par exemple, « GraphPowerShell »). Assurez-vous d'ajouter les modules nécessaires : Microsoft.Graph.Authentication, Microsoft.Graph.Users.
    ![create-runtime](images/create-runtime.png)
    - Naviguez vers Runbooks et créez un nouveau Runbook. Appelez-le « ProcessUserProfileRequests ». Assurez-vous de sélectionner l'environnement d'exécution créé précédemment.
    ![create-runbook](images/create-runbook.png)
    - Lorsque l'éditeur de runbook s'ouvre, remplacez le code par défaut par le script PowerShell de l'étape 4. Assurez-vous d'avoir remplacé les détails de l'inscription d'application par ceux créés à l'étape 2.
    ![editor](images/editor.png)
    - Enregistrez et publiez le Runbook.
    - Testez le Runbook pour vous assurer qu'il fonctionne comme prévu en cliquant sur le bouton « Démarrer » dans la page de présentation du Runbook.
    ![start-runbook](images/start-runbook.png)
    - Vous devriez voir la sortie dans la page des détails du travail.
    ![job-detail](images/job-detail.png)

6. **Créez une LogicApp** : Créez une Logic App pour déclencher le script PowerShell lorsqu'un nouvel élément est ajouté à la liste SharePoint.
    - Ouvrez un nouvel onglet de navigateur.
    - Dans le portail Azure, naviguez vers le groupe de ressources créé précédemment.
    - Créez une nouvelle Logic App.
    ![create-logicapp](images/create-logicapp.png)
    - Choisissez le plan « Consommation ».
    - Nommez la Logic App (par exemple, « logic-user-profile-listener-<vos initiales> »). La raison d'ajouter vos initiales est d'éviter les conflits de noms.
    ![create-logicapp-2](images/create-logicapp-2.png)
    - Activez l'identité de la Logic App sous la section « Identité ».
    ![logicapp-identity](images/logicapp-identity.png)
    - Basculez vers l'onglet du navigateur du compte Automation. Naviguez vers la section « Contrôle d'accès (IAM) » et attribuez les rôles « Automation Job Operator » et « Automation Operator » à l'identité de la Logic App.
    ![iam-aa-la](images/iam-aa-la.png)
    - Revenez à l'onglet du navigateur de la Logic App. Ouvrez le concepteur de Logic App.
    ![open-designer](images/open-designer.png)
    - Dans le concepteur de Logic App, configurez un déclencheur pour « Quand un élément est créé » dans SharePoint.
    ![la-trigger](images/la-trigger.png)
    - Assurez-vous que l'utilisateur que vous utilisez pour connecter le connecteur SharePoint a accès au site SharePoint.
    ![la-trigger-2](images/la-trigger-2.png)
    - Ajoutez une action pour démarrer le Runbook « ProcessUserProfileRequests » dans le compte Automation. Vous devrez entrer manuellement l'abonnement et le groupe de ressources. Les autres champs devraient se remplir automatiquement. C'est parce que la Logic App a accès au compte Automation mais pas aux ressources parentes.
    ![configure-job](images/configure-job.png)
    - Ajoutez une autre tâche pour récupérer la sortie du travail après l'exécution du Runbook.
    ![job-output](images/job-output.png)
    - Ajoutez une tâche « Mettre à jour l'élément » et mappez les paramètres ProfileInfo et RequestStatus pour l'élément SharePoint.
    ![update-item](images/update-item.png)

7. **Test du laboratoire** : Testez l'ensemble de la configuration en ajoutant un nouvel élément à la liste SharePoint. La Logic App devrait se déclencher dans les minutes suivantes, si vous souhaitez accélérer le processus, vous pouvez déclencher manuellement la Logic App. Le script PowerShell devrait s'exécuter et mettre à jour l'élément de liste SharePoint avec les informations de profil de l'utilisateur depuis Entra.
![final](images/final.png)