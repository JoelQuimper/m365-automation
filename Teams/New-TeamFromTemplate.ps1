param (
    [Parameter(Mandatory = $true)]
    [string]$TeamName,

    [Parameter(Mandatory = $true)]
    [string]$TeamDescription,

    [Parameter(Mandatory = $true)]
    [array]$TeamOwners,

    [Parameter(Mandatory = $false)]
    [string]$TeamTemplateName = "Basic"
)

"Creating team $TeamName with description $TeamDescription and template $TeamTemplateName"
foreach ($owner in $TeamOwners) {
    "Owner: $owner"
}
try {
    # Connect to Graph using custom module
    Connect-GraphContext

    # get owners guid
    $owners = @()
    foreach ($owner in $TeamOwners) {
        $ownerGraph = Get-MgUser -UserId $owner
        $owners += "https://graph.microsoft.com/v1.0/users/$($ownerGraph.Id)"
    }

    $basicTemplate = @{
        groupTemplate = @{
            description = $TeamDescription
            displayName = $TeamName
            groupTypes = @(
                "Unified"
            )
            visibility = "Private"
            mailEnabled = $true
            mailNickname = "basic-$TeamName" #on devrait ajouter une function au module afin de générer un mailNickname à partir du displayName
            securityEnabled = $false
            "owners@odata.bind" = $owners
        }
        teamTemaplate = @{
            memberSettings = @{
                allowCreatePrivateChannels = $true
                allowCreateUpdateChannels = $true
            }
            messagingSettings = @{
                allowUserEditMessages = $true
                allowUserDeleteMessages = $true
            }
            funSettings = @{
                allowGiphy = $true
                giphyContentRating = "strict"
            }
        }
    }

    "Creating group first in order to control mailnickname and siteurl"
    $group = New-MgGroup -BodyParameter $basicTemplate.groupTemplate
    "Group created successfully. GroupId: $($group.Id)"

    Start-Sleep -Seconds 30

    "Adding Team to group"
    Set-MgGroupTeam -GroupId $group.Id -BodyParameter $basicTemplate.teamTemaplate

    "Team $TeamName created successfully."
} catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}