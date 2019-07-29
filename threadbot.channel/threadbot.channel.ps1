#requires -Module PSFramework
<#
.SYNOPSIS
    Suggest Slack threads for busy rooms with a lot of messages occurring outside of threads at the channel level to remind users to use threads
.DESCRIPTION
    This middleware tracks how many messages (x) users in a channel send per (y) amount of time.
    If a channel goes over the threshold, we'll send a message suggesting that Slack threads should be used.
.NOTES
    Based on https://stackoverflow.com/questions/667508/whats-a-good-rate-limiting-algorithm
    2019-07-29 Modified by Sheldon Hull significantly for monitoring CHANNEL level not user. This suggests threads when people keep posting in a single channel without using threads in the source of minutes.
    My test case was 15 mins allowed up to 6 messages, at 7 warns.
    However, it also looks for sending :eyes: reaction to any messages over 3-7 so that it alerts people to "ThreadBot" watching
    Be prepared for mutinies against ThreadBot

.LINK
    https://devblackops.io/poshbot-middleware-for-ratelimiting/
#>
param(
    $Context,
    $Bot,
    $MaximumMessages = 5
    ,$TimePeriodToMonitorSec = 900
)

$Bot.LogDebug('Beginning message ratelimit middleware')
$ChannelId = $Context.Message.To
$ChannelName = $ChannelId #$$Context.Message

$maxMsgs    = $MaximumMessages
$StartWarningAt = [math]::Ceiling(($maxMsgs / 2)) #calculate the approx half-way point to start reacting to messsages
$timePeriod = $TimePeriodToMonitorSec
$datadirectory = Join-Path $Bot.Configuration.ConfigurationDirectory 'data-channels'
$ThreadDirectory = Join-Path $Bot.Configuration.ConfigurationDirectory 'data-threads'

# Only measure messages NOT already in a thread
# This middlware hook stage also receives extra messages whenever a user replies in a thread
# We need to ensure we DON'T count these against the rate limiting
$unThreadedMsg = (
    ([string]::IsNullOrWhiteSpace($Context.Message.RawMessage.thread_ts) -and
        ($Context.Message.RawMessage.type -eq 'message' -and $Context.Message.RawMessage.subtype -ne 'message_replied'))
)
if ($unThreadedMsg)
{
    New-Item -path $DataDirectory -ItemType Directory -ErrorAction SilentlyContinue
    # Load the tracker
    $trackerPath = Join-Path $DataDirectory  ('{0}_msg_ratelimiting_tracking.clixml' -f $ChannelId)

    if (Test-Path $trackerPath)
    {
        $tracker = Import-Clixml $trackerPath
    }
    else
    {
        $tracker = @{
            Allowance   = $maxMsgs
            LastMsgTime = [datetime]::UtcNow
        }
    }

    $now        = [datetime]::UtcNow
    $timePassed = ($now - $tracker.LastMsgTime).TotalSeconds
    $tracker.LastMsgTime = $now
    $tracker.Allowance  += $timePassed * ($maxMsgs / $timePeriod)

    if ($tracker.Allowance -gt $maxMsgs)
    {
        $tracker.Allowance = $maxMsgs
    }

    If ($tracker.Allowance -lt 1.0)
    {
        $Bot.LogDebug("Channel has breached ratelimit of [$maxMsgs] messages in [$timePeriod] seconds. Sending thread reminder response")
        $response                 = [Response]::new()
        $response.To              = $Context.Message.To
        $response.MessageFrom     = $Context.Message.From
        $response.OriginalMessage = $Context.Message

        $text = @(
            ":eyes: threadbot is watching...more threads = :taco:"
            ":eyes: threadbot is watching...threads make :robot_face: happy"
            ":eyes: threadbot is watching...the lack of threads ... :hear_no_evil:"
            ":eyes: threadbot has a :broken_heart:"
            ":eyes: threadbot ... :sob:"
            ":eyes: threadbot ... :scream:"
            ":eyes: threadbot ... :wondering:"
            ":eyes: threadbot ... don't make me call :batman:"

        ) | Sort-Object { Get-Random} | Select-Object -First 1




        $response.Data = New-PoshBotTextResponse -Text $text #-AsCode
        $Bot.Backend.AddReaction($Context.Message, [ReactionType]::Custom, 'eyes')
        Start-Sleep -Seconds 1
        $Bot.SendMessage($response)
        $Bot.LogDebug('Sending thread reminding response')
        $tracker.Allowance = $maxMsgs

    }
    else
    {
        $tracker.Allowance -= 1.0
        if ($tracker.Allowance -ge 0 -and $tracker.Allowance -le $StartWarningAt)
        {
            # Add reaction to original message
            $Bot.LogDebug("$ChannelName Allowance < `$StartWarningAt: $StartWarningAt // $($tracker.Allowance) left. Adding eyes reaction")
            $Bot.Backend.AddReaction($Context.Message, [ReactionType]::Custom, 'eyes')
        }

    }

    $tracker | Export-Clixml -Path $trackerPath
}
else
{
    New-Item -path $ThreadDirectory -ItemType Directory -ErrorAction SilentlyContinue
    # Load the tracker
    $trackerPath = Join-Path $ThreadDirectory  ('{0}_msg_thread_counts.clixml' -f $ChannelId)

    if (Test-Path $trackerPath)
    {
        $tracker = Import-Clixml $trackerPath
        $tracker['TotalThreadedMessages'] += 1
    }
    else
    {
        $tracker = @{
            TotalThreadedMessages = 1
            RewardReactions       = 1
            LastMsgTime           = [datetime]::UtcNow
        }
    }


    $Bot.LogDebug("Ignoring message. It's already in a threaded conversation.")
    $random = Get-Random -minimum 1 -maximum 10
    if ($Random % 2 -eq 0)
    {
        $Bot.LogDebug("$ChannelName Using threaded message. Random reaction rewards for this")
        $reaction =  @(
            'yes'
            'tada'
            'grin'
            'firework'
            'v'
            'bananadance'
            'partyparrot'
            'beers'
            'lollipop'
        ) | Sort-Object { Get-Random} | Select-Object -First 1
        $Bot.Backend.AddReaction($Context.Message, [ReactionType]::Custom, $reaction)
        $tracker['RewardReactions'] += 1
    }

 <#
 ##TODO: some type of badge or award for thread usage at channel level. never finished implementing
 $r = $tracker['RewardReactions']
if($r -ge 10 -and $r -lt 25 )
{
}
if($r -ge 25 -and $r -lt 50 )
{
}
if($r -ge 50 -and $r -lt 25 )
{
}
 #>
    $tracker | Export-Clixml -Path $trackerPath

}

# Pass context for any subsequent middleware
$Bot.LogDebug('Ending message ratelimit middleware')
$Context