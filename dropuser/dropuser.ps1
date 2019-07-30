<#
.SYNOPSIS
    Drops all messages from a given list of users
.DESCRIPTION
    There may be times where you need to drop ALL PoshBot commands from certain users before
    they are executed. This middleware hook does just that.
#>
param(
    $Context,
    $Bot
)

$blacklistedUsers = @('sally', 'bob')
$user = $Context.Message.FromName

# Optionally, you can use user IDs in place of user names.
# $blacklistedUsers = @('U4ACMBKH9', 'U5BNMSYH6')
# $user = $Context.Message.From

$Bot.LogDebug('Running user drop middleware')
if ($blacklistedUsers -contains $user) {
    $Bot.LogInfo("User [$user] is blacklisted. Dropping message.")
    return
}

$Context