#requires -Module PSFramework
<#
.SYNOPSIS
    Suggest Slack threads for busy rooms with a lot of messages occurring outside of threads at the channel level to remind users to use threads
.DESCRIPTION
    This middleware tracks how many messages (x) users in a channel send per (y) amount of time.
    If a channel goes over the threshold, we'll send a message suggesting that Slack threads should be used.
.PARAMETER ExcludeChannels
    ChannelId to exclude from evaluation, using the slack naming `GHL231349` type format
.PARAMETER RandomMessages
    Default: False
    Random warning messages. I put this in as a switch as might be confusing to some users if they really don't understand threads, so starting off with more simple friendly message
.PARAMETER maxMsgs
    Maximum messages before warning in a channel
.PARAMETER timePeriod
    Timeperiod to sample the messages. For instance, setting at 15 minutes in a channel that isn't busy can catch delayed responses outside of threads, while a busy channel might want to narrow to a smaller time period
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
    $excludeChannels = @(''),
    [int]$maxMsgs    = 5,
    [int]$timePeriod = 900,
    [switch]$RandomMessages

)

$Bot.LogDebug('Beginning message ratelimit middleware')
$Bot.LogDebug('This was identified as a Direct Message')
$ChannelId = $Context.Message.To
$ChannelName = $ChannelId


if ($ChannelId -in  $excludeChannels)
{
    $Bot.LogDebug("$ChannelId - in exclusion list, bypassing any further middleware processing")
    $Context
    return
}

if ($context.Message.IsDM)
{
    $Bot.LogDebug("Message is a direct message. Excluding from processing")
    $Context
    return
}

# We'll allow (5) messages per user in a xsecond second window before suggesting threads

$StartWarningAt = [math]::Ceiling(($maxMsgs / 2))
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

        if ($RandomMessages)
        {
            $text = @(
                ":eyes: threadbot is watching...more threads = :taco:"
                ":eyes: threadbot is watching...threads make :robot_face: happy"
                ":eyes: threadbot is watching...the lack of threads ... :hear_no_evil:"
                ":eyes: threadbot has a :broken_heart:"
                ":eyes: threadbot ... :sob:"
                ":eyes: threadbot ... :scream:"
                ":eyes: threadbot ... :wondering:"
                ":eyes: threadbot ... don't make me call :batman:"

            ) | Sort-Object { Get-Random } | Select-Object -First 1
        }
        else
        {
            $text = ":robot_face: friendly reminder to use threads when possible. This helps keep context and reduce the noise on discussions to only those who need it. :taco: for your efforts!"
        }

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
    ### FOR THREADED MESSAGES GIVE POSITIVE FEEDBACK EVERY 10 THREADED MESSAGES IN THE CHANNEL

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
    $currentthreadedmessage = $tracker['TotalThreadedMessages']
    $Bot.LogDebug("Ignoring message. It's already in a threaded conversation.")

    if ($currentthreadedmessage % 10 -eq 0)
    {
        $Bot.LogDebug("$ChannelName Using threaded message. $currentthreadedmessage must be divisible by 10 to add reaction to throttle reactions")
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
        ) | Sort-Object { Get-Random } | Select-Object -First 1
        $Bot.Backend.AddReaction($Context.Message, [ReactionType]::Custom, $reaction)
        $tracker['RewardReactions'] += 1
    }
    $tracker | Export-Clixml -Path $trackerPath
}

# Pass context for any subsequent middleware
$Bot.LogDebug('Ending message ratelimit middleware')
$Context