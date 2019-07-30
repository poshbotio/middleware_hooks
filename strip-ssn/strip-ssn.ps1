<#
.SYNOPSIS
    Detects possible Social Security numbers (SSNs) in command responses and sanitizes them.
.DESCRIPTION
    When a command response is sent back to the chat network, this middleware will search
    for possible SSNs and sanitize them.
#>
param(
    $Context,
    $Bot
)

if ($Context.Response.Text -match '\d\d\d-\d\d-\d\d\d\d') {
    $Bot.LogInfo('SSN detected in response. Sanitizing...')
    $Context.Response.Text -replace '\d\d\d-\d\d-\d\d\d\d', '###-##-####'
}

$Context