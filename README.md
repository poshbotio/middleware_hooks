<h1 align="center">👋 Welcome to PoshBot Middleware Hook Repo 👋</h1>
<p>
  <a href="https://poshbot.readthedocs.io/en/latest/guides/middleware/">
    <img alt="Documentation" src="https://img.shields.io/badge/documentation-yes-brightgreen.svg" target="_blank" />
  </a>
</p>

> This repository is a collection of useful middleware hooks developed by the community.
> Feel free to use these or take inspiration from them and create your own. **Please** consider contributing back so others can benefit from them as well.

## What is PoshBot Middlware

[PoshBot](https://github.com/poshbotio/PoshBot) has the concept of [middlware hooks](http://docs.poshbot.io/en/latest/guides/middleware/#middleware-hooks), which is the ability to execute custom PowerShell scripts during certain events in the command processing lifecycle.
These hooks can do pretty much anything you want.
After all, they are just PowerShell scripts.
Middlware can add centralized authentication logic, custom logging solutions, advanced whitelisting or blacklisting, or any other custom processes.
This middleware allows you to extend the utility of your ChatOps environment.
Read [this blog post](https://devblackops.io/poshbot-middleware-for-ratelimiting/) about an example usage of middleware.

## Middleware Documentation

Detailed documentation about middleware hooks can be found on the [ReadTheDocs]((https://poshbot.readthedocs.io/en/latest/guides/middleware/)) site.

## Install

To copy this repository locally run:

```powershell
git clone https://github.com/poshbotio/middleware_hooks.git
```

## Usage

To add middleware to PoshBot, you need a configuration object first.
The code below will create a configuration with default values.

```powershell
$config = New-PoshBotConfiguration
```

Next, you use `New-PoshBotMiddlewareHook`.
This command takes the name of the middleware hook and the path to the PowerShell script to execute.

```powershell
$preReceiveHook = New-PoshBotMiddlewareHook -Name 'prereceive' -Path 'c:/poshbot/middleware/prereceive.ps1'
```

This middleware is then added to the bot configuration object with the code below.
When adding middleware to the `MiddlewareConfiguration` property, use the `Add()` method, passing in the middleware object you created above, and the type of middleware.
The types are `PreReceive`, `PostReceive`, `PreExecute`, `PostExecute`, `PreResponse`, and `PostResponse`.
You can read more about the differences between these types [here](http://docs.poshbot.io/en/latest/guides/middleware/#middlewareconfiguration).

```powershell
$config.MiddlewareConfiguration.Add($preReceiveHook, 'PreReceive')
```

Similarly, middleware can be removed using the Remove() method.

```powershell
$config.MiddlewareConfiguration.Remove($preReceiveHook, 'PreReceive')
```

A new instance of PoshBot is created and starting using the configuration object below.

```powershell
$backend = New-PoshBotSlackBackend -Configuration $config.BackendConfiguration
$bot = New-PoshBotInstance -Backend $backend -Configuration $config
$bot | Start-PoshBot
```

## Advanced Usage

Here is a more advanced example of defining a PoshBot configuration, adding a middleware hook, and starting PoshBot.

```powershell
#requires -Version 5.1
# This uses PS 5.1 since this is leveraging Windows Credential Manager. PoshBot itself supports PowerShell 5 and above, including PowerShell Core on Linux/macOS.

param(
    $SlackUserName = '@MyUser.Name',
    $BotName = 'poshbot'
)

if (@(Get-Module -Name PoshBot -ListAvailable).Count -eq 0) {
    Install-Module PoshBot -Verbose:$false -Force
}
Import-Module PoshBot, PSSlack, BetterCredentials

# Cached credentials pulled via BetterCredentials
$botCred = Find-Credential 'slack.bot.poshbot'

# Define bot configuration
$token       = $botCred.GetNetworkCredential().Password
$BotName     = $BotName # The name of the bot we created
$botAdmin    = $SlackUserName  # My account name in Slack
$poshbotPath = Join-Path $PSScriptRoot 'poshbot'

# Configure differently if you want middleware to be a different git repo
$middleWareFolderPath = Join-Path $poshbotPath 'middleware'

New-Item -Path $poshbotPath -Force -ItemType Directory -ErrorAction SilentlyContinue
$configPath  = Join-Path $poshbotPath config.psd1
$pluginPath  = Join-Path $poshbotPath plugins
$logPath     = Join-Path $poshbotPath logs

# Middleware hooks like processing messages and parsing for behavior (all messages, not just commands)
$middlewareHookPath = Join-Path $middleWareFolderPath 'threadbot.channel.ps1'
$threadbotHook      = New-PoshBotMiddlewareHook -Name 'threadbot-channel' -Path $middlewareHookPath

# Create a PoshBot configuration
$botParams = @{
    Name                      = $BotName
    BotAdmins                 = $botAdmin
    CommandPrefix             = '!'
    LogLevel                  = 'Info'
    BackendConfiguration      =  @{Name = 'SlackBackend'; Token = $token }
    AlternateCommandPrefixes  = 'bender', 'hal'
    ConfigurationDirectory    = $poshbotPath
    LogDirectory              = $logPath
    PluginDirectory           = $pluginPath
    PreReceiveMiddlewareHooks = $threadbotHook
}

# Persist connection & configuration Settings
$null = mkdir $poshbotPath, $pluginPath, $logPath -Force

Write-PSFMessage -Level Important -Message 'Creating bot configuration and instance'
$config  = New-PoshBotConfiguration @botParams
Save-PoshBotConfiguration -InputObject $config -Path $configPath -Force
$backend = New-PoshBotSlackBackend -Configuration $config.BackendConfiguration
$bot     = New-PoshBotInstance -Configuration $config -Backend $backend

# Start PoshBot
Start-PoshBot -Configuration $config -ErrorAction Continue
```

## Contributing

Contributions, issues, and feature requests are welcome! 🤝

Feel free to check out the [issues page](https://github.com/poshbotio/middleware_hooks/issues) if you are experiencing any problems.

### New Hooks

To contribute a new hook:

1. [Fork this repository](https://guides.github.com/activities/forking/)
2. Create a new branch
3. Add your you hook to a sensibly named subfolder
4. Create a `README.md` in the subfolder explaining what the hook does and how to configure it (use the `template_readme.md` as a guide)
5. Submit a [pull request](https://help.github.com/en/articles/creating-a-pull-request)
6. Rejoice 🎉

### Improving Existing Hooks

1. [Fork this repository](https://guides.github.com/activities/forking/)
2. Create a new branch
3. Add your improvements to the middleware hook
4. Submit a [pull request](https://help.github.com/en/articles/creating-a-pull-request)
5. Rejoice 🎉

## Show your support

Star this project if it has helped you! ⭐️
