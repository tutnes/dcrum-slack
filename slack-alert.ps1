#requires -Version 3
#
# Used this function https://raw.githubusercontent.com/WahlNetwork/powershell-scripts/master/Slack/Post-ToSlack.ps1
# And used this https://community.dynatrace.com/community/display/PUBDCRUM/ServiceNow+Integration for wrapper
#
#

param (
    [string]$dcrum_message = "",
    [bool]$debug = 0
)

function Post-ToSlack 
{
    <#  
            .SYNOPSIS
            Sends a chat message to a Slack organization
            .DESCRIPTION
            The Post-ToSlack cmdlet is used to send a chat message to a Slack channel, group, or person.
            Slack requires a token to authenticate to an org. Either place a file named token.txt in the same directory as this cmdlet,
            or provide the token using the -token parameter. For more details on Slack tokens, use Get-Help with the -Full arg.
            .NOTES
            Written by Chris Wahl for community usage
            Twitter: @ChrisWahl
            GitHub: chriswahl
            .EXAMPLE
            Post-ToSlack -channel '#general' -message 'Hello everyone!' -botname 'The Borg'
            This will send a message to the #General channel, and the bot's name will be The Borg.
            .EXAMPLE
            Post-ToSlack -channel '#general' -message 'Hello everyone!' -token '1234567890'
            This will send a message to the #General channel using a specific token 1234567890, and the bot's name will be default (PowerShell Bot).
            .LINK
            Validate or update your Slack tokens:
            https://api.slack.com/tokens
            Create a Slack token:
            https://api.slack.com/web
            More information on Bot Users:
            https://api.slack.com/bot-users
    #>

    Param(
        [Parameter(Mandatory = $true,Position = 0,HelpMessage = 'Slack channel')]
        [ValidateNotNullorEmpty()]
        [String]$Channel,
        [Parameter(Mandatory = $true,Position = 1,HelpMessage = 'Chat message')]
        [ValidateNotNullorEmpty()]
        [String]$Message,
        [Parameter(Mandatory = $false,Position = 2,HelpMessage = 'Slack API token')]
        [ValidateNotNullorEmpty()]
        [String]$token,
        [Parameter(Mandatory = $false,Position = 3,HelpMessage = 'Optional name for the bot')]
        [String]$BotName = 'PowerShell Bot'
    )

    Process {

        # Static parameters
        if (!$token) 
        {
            $token = Get-Content -Path "$PSScriptRoot\token.txt"
        }
        $uri = 'https://slack.com/api/chat.postMessage'

        # Build the body as per https://api.slack.com/methods/chat.postMessage
        $body = @{
            token    = $token
            channel  = $Channel
            text     = $Message
            username = $BotName
            parse    = 'full'
        }

        # Call the API
        try 
        {
            Invoke-RestMethod -Uri $uri -Body $body
        }
        catch 
        {
            throw 'Unable to call the API'
        }

    } # End of process
} # End of function



 
Try
{

# Writing log information in debug mode including parameters that were included in the call
if ($debug -eq 1)
{
 $time=Get-Date
 "$time New alert notification received " | Add-Content service-now.log
 "Script parameters " | Add-Content service-now.log    
 foreach ($key in $MyInvocation.BoundParameters.keys)
 {
    $value = (get-variable $key).Value 
    $keyheader = $key.ToString().ToUpper();
    if (![string]::IsNullOrEmpty($value))
    {
        "$keyheader : $value" |   Add-Content service-now.log
    }
 }
}

# In case of error writing exception details to log file
Catch
{
    if ($debug -eq 1)
    {
           $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
           $time=Get-Date
           "$time error
           $ErrorMessage
           $FailedItem" | Add-Content slack-alert.log
    }
} 

#################
# Configuration #
#               #
#################
$channel = '#your-channel-here'
$botname = 'Secret Ninja'
$result = Post-ToSlack -Channel $channel -Message $dcrum_message -BotName $botname

# Validate the results
if ($result.ok)
{
 Write-Host -Object 'Success! The important message was sent!'
}
else
{
 Write-Host -Object 'It failed! Abort the mission!'
}