<#
.SYNOPSIS
    Loads the lab's ticket bank (tickets/tickets.json) into GLPI through its REST API.

.DESCRIPTION
    Creates the ITIL categories and requester accounts the tickets need (skipping any that
    already exist), then opens one GLPI ticket per scenario with the right type, urgency,
    impact, category and requester. Run scripts/enable-api.sh first to get an app token.

.EXAMPLE
    ./scripts/Import-LabTickets.ps1 -AppToken <token> -Credential (Get-Credential glpi)

.EXAMPLE
    ./scripts/Import-LabTickets.ps1 -AppToken <token> -Credential (Get-Credential glpi) -WhatIf
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)] [string] $AppToken,
    [Parameter(Mandatory)] [pscredential] $Credential,
    [string] $BaseUrl = 'http://127.0.0.1:8090/apirest.php',
    [string] $TicketFile = (Join-Path $PSScriptRoot '..' 'tickets' 'tickets.json')
)

$ErrorActionPreference = 'Stop'
$script:Cmdlet = $PSCmdlet

# GLPI ticket types: 1 = incident (something broke), 2 = request (something is needed).
$TicketType = @{ incident = 1; request = 2 }

function Invoke-Glpi {
    param([string] $Method, [string] $Path, [object] $Body)
    $params = @{ Method = $Method; Uri = "$BaseUrl/$Path"; Headers = $script:Headers; ContentType = 'application/json' }
    if ($Body) { $params.Body = ($Body | ConvertTo-Json -Depth 5) }
    Invoke-RestMethod @params
}

function Get-OrCreate {
    # Looks an item up by exact name and creates it if missing. Returns its ID.
    param([string] $ItemType, [string] $Name, [hashtable] $Fields)
    $found = Invoke-Glpi GET "$ItemType`?searchText[name]=$([uri]::EscapeDataString($Name))&range=0-999" |
        Where-Object { $_.name -eq $Name } | Select-Object -First 1
    if ($found) { return $found.id }
    if (-not $script:Cmdlet.ShouldProcess("$ItemType '$Name'", 'Create')) { return 0 }
    (Invoke-Glpi POST $ItemType @{ input = ($Fields + @{ name = $Name }) }).id
}

$tickets = Get-Content $TicketFile -Raw | ConvertFrom-Json

# Open an API session with the GLPI login.
$basic = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(
    "$($Credential.UserName):$($Credential.GetNetworkCredential().Password)"))
$session = Invoke-RestMethod -Uri "$BaseUrl/initSession" -Headers @{ 'App-Token' = $AppToken; Authorization = "Basic $basic" }
$script:Headers = @{ 'App-Token' = $AppToken; 'Session-Token' = $session.session_token }

try {
    $categoryIds = @{}
    foreach ($name in ($tickets.category | Sort-Object -Unique)) {
        $categoryIds[$name] = Get-OrCreate ITILCategory $name @{ is_helpdeskvisible = 1; is_incident = 1; is_request = 1 }
    }

    $userIds = @{}
    foreach ($requester in ($tickets.requester | Sort-Object -Unique)) {
        # "Priya Shah (Finance)" -> login priya.shah ; "Front Desk" -> front.desk
        $display = ($requester -replace '\s*\(.*\)$', '').Trim()
        $login = ($display.ToLower() -replace '[^a-z ]', '' -replace '\s+', '.')
        $first, $last = $display.Split(' ', 2)
        $userIds[$requester] = Get-OrCreate User $login @{ firstname = $first; realname = $last; is_active = 1 }
    }

    $created = 0
    foreach ($t in $tickets) {
        $title = "[$($t.id)] $($t.title)"
        if (-not $PSCmdlet.ShouldProcess($title, 'Open ticket')) { continue }
        $existing = Invoke-Glpi GET "Ticket?searchText[name]=$([uri]::EscapeDataString("[$($t.id)]"))&range=0-999"
        if ($existing | Where-Object { $_.name.StartsWith("[$($t.id)]") }) { Write-Verbose "Skipping $title (exists)"; continue }

        $null = Invoke-Glpi POST Ticket @{ input = @{
            name                 = $title
            content              = "$($t.description)`n`nRequester: $($t.requester)"
            type                 = $TicketType[$t.type]
            urgency              = $t.urgency
            impact               = $t.impact
            itilcategories_id    = $categoryIds[$t.category]
            _users_id_requester  = $userIds[$t.requester]
        } }
        $created++
    }
    Write-Output "Opened $created ticket(s); $($tickets.Count - $created) skipped."
}
finally {
    Invoke-Glpi GET killSession | Out-Null
}
