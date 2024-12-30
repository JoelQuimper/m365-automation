param (
    [Parameter(Mandatory = $false)]
    [int]$ActivityPeriodInDays = 180
)

"Getting teams activity for the last $ActivityPeriodInDays days"
try {
    # Connect to Graph using custom module
    Connect-GraphContext

    $tempFile = New-TemporaryFile
    # by default, teams hide PII in the report (name and id of teams).  They are needed, to activate PII see https://learn.microsoft.com/en-US/microsoft-365/admin/activity-reports/activity-reports?WT.mc_id=365AdminCSH_inproduct&view=o365-worldwide#show-user-details-in-the-reports
    Get-MgReportTeamActivityDetail -Period "D$ActivityPeriodInDays" -OutFile $tempFile
    $teamsActivity = Import-Csv $tempFile.FullName
    "There are $($teamsActivity.Count) teams"
    foreach ($team in $teamsActivity) {
        "##### Team name : $($team.'Team Name'), id : $($team.'Team Id'), last activity : $($team.'Last Activity Date')"

        # retrouver tous les owner du teams
        $members = Get-MgTeamMember -TeamId $team.'Team Id'
        "There are $($members.Count) members"
        $owners = New-Object System.Collections.ArrayList
        foreach ($member in $members) {
            if($member.Roles -contains "owner") {
                " - Owner name: $($member.DisplayName), id: $($member.Id)"
                $owners += $member
            }
        }
        "There are $($owners.Count) owners"
    }
} catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}