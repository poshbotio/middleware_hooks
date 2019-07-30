<#
.SYNOPSIS
    Validates that a given chat user is a member of an Active Directory group before allowing command execution.
.DESCRIPTION
    This middleware hook takes the user name property of the incomming message and validates if the user is
    a member of the specified Active Directory group. If the user is a member, the command is allowed. If not,
    the message is dropped.
#>
param(
    $Context,
    $Bot
)

$user    = $Context.Message.FromName
$adGroup = 'botusers'

$userGroups = (New-Object System.DirectoryServices.DirectorySearcher("(&(objectCategory=User)(samAccountName=$user)))")).FindOne().GetDirectoryEntry().memberOf
if (-not ($userGroups -contains $adGroup)) {
    $Bot.LogInfo("User [$user] is not in AD group [$adGroup]. Bot commands cannot be run.")
    return
} else {
    $Context
}