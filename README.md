<h1 align="center">Welcome to PoshBot Middleware Hook Repo 👋</h1>
<p>
  <a href="https://poshbot.readthedocs.io/en/latest/guides/middleware/">
    <img alt="Documentation" src="https://img.shields.io/badge/documentation-yes-brightgreen.svg" target="_blank" />
  </a>
</p>

> A public repository of middleware hooks to use in PoshBot

### 🏠 [Homepage](https://poshbot.readthedocs.io/en/latest/guides/middleware/)

## Install

```powershell
git clone https://github.com/poshbotio/middleware_hooks.git
```

## Usage

Reference the contents of the middleware hook in your bot configuration.
For example:

```powershell
#requires -Version 5.1
param(
  $SlackUserName = '@MyUser.Name'
  ,$BotName = 'poshbot'

)
# I use 5.1 since this is leveraging Windows Credential Manager, as well as I wanted to be able to handle other windows specific things. I had some issues with 6.2 and poshbot, but never had a chance to iron them out. Some plugins I tried didn't work in PowerShell core, so I just reverted to 5.1 for now
$script:Directory = $PSScriptRoot


if (@(Get-Module -Name PoshBot -ListAvailable).count -eq 0)
{ Install-Module PoshBot -verbose:$false -Force }
Import-Module PoshBot, PSSlack,BetterCredentials

#----------------------------------------------------------------------------#
#  Cached Credentials Pulled Via BetterCredentialsefine Bot Configuration    #
#----------------------------------------------------------------------------#

$botcred = Find-Credential 'slack.bot.poshbot'
#----------------------------------------------------------------------------#
#                          Define Bot Configuration                          #
#----------------------------------------------------------------------------#

$Token = $botcred.GetNetworkCredential().Password
$BotName = $BotName # The name of the bot we created
$BotAdmin = $SlackUserName  # My account name in Slack
$PoshbotPath = Join-Path $script:Directory 'poshbot'

#configure differently if you want middleware to be a different git repo
$MiddleWareFolder = Join-Path $PoshBotpath 'middleware'

New-Item -Path $PoshbotPath -Force -ItemType Directory -ErrorAction SilentlyContinue
$PoshbotConfig = Join-Path $PoshbotPath config.psd1
$PoshbotPlugins = Join-Path $PoshbotPath plugins
$PoshbotLogs = Join-Path $PoshbotPath logs

# Middleware hooks like processing messages and parsing for behavior (all messages, not just commands)
$threadbotHook = New-PoshBotMiddlewareHook -Name 'threadbot-channel' -Path (Join-Path $MiddleWareFolder 'threadbot.channel.ps1')

#----------------------------------------------------------------------------#
#                 Create Configuration & Backend Credentials                 #
#----------------------------------------------------------------------------#

# Create a PoshBot configuration
$BotParams = @{
    Name                      = $BotName
    BotAdmins                 = $BotAdmin
    CommandPrefix             = '!'
    LogLevel                  = 'Info'
    BackendConfiguration      =  @{Name = 'SlackBackend'; Token = $Token }
    AlternateCommandPrefixes  = 'bender', 'hal'
    ConfigurationDirectory    = $PoshbotPath
    LogDirectory              = $PoshbotLogs
    PluginDirectory           = $PoshbotPlugins
    PreReceiveMiddlewareHooks = $threadbotHook
}


#----------------------------------------------------------------------------#
#                Persist Connection & Configuration Settings                 #
#----------------------------------------------------------------------------#
$null = mkdir $PoshbotPath, $PoshbotPlugins, $PoshbotLogs -Force

Write-PSFMessage -Level Important -Message 'Creating bot configuration and instance'
$config  = New-PoshBotConfiguration @BotParams
Save-PoshBotConfiguration -InputObject $config -Path $PoshbotConfig -Force
$backend = New-PoshBotSlackBackend -Configuration $config.BackendConfiguration
$bot     = New-PoshBotInstance -Configuration $config -Backend $backend

#----------------------------------------------------------------------------#
#                               Start PoshBot                                #
#----------------------------------------------------------------------------#
Start-PoshBot -Configuration $config -ErrorAction Continue

```

## 🤝 Contributing

Contributions, issues and feature requests are welcome!<br />
Feel free to check [issues page](https://github.com/poshbotio/middleware_hooks/issues).

To contribute, fork this repository, add your changes, and then create a readme in a folder with the same name as your script, along with a readme (using the template provided as `template_readme.md` and submit pull request.

## Show your support

Give a ⭐️ if this project helped you!

***
_This README was generated with ❤️ by [readme-md-generator](https://github.com/kefranabg/readme-md-generator)_