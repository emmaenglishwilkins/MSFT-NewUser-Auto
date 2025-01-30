<#
    .Author
	Trevor Sullivan <trevor@trevorsullivan.net>
	https://trevorsullivan.net
	https://twitter.com/pcgeek86
	
	.Description
	This Azure Automation Runbook serves as a template for bi-directionally integrating Microsoft Azure Automation
	with the Slack chat service, through the use of Webhooks for Slack and Azure Automation. You can build your own
	custom commands, similar to the ones that are defined towards the bottom of this Runbook. The Get-SlackParameter
	and Send-SlackMessage funcions are provided as helpful plumbing.
	
	NOTE: You need to configure a "custom slash command" for your Slack organization, as well as an "incoming webhook"
		  in order to take advantage of all of the features of this Azure Automation Runbook.
#>
param (
	[Object] $WebhookData
)

### Build a function that accepts Slack parameters 
function Get-SlackParameter {
	<#
	.Synopsis
	This function takes the input parameters to a Webhook call by the Slack service. The function translates the query
	string, provided by the Slack service, and returns a PowerShell HashTable of key-value pairs. Azure Automation accepts
	a $WebhookData input parameter, for Webhook invocations, and you should pass the value of the RequestBody property
	into this function's WebhookPayload parameter.
	
	.Parameter WebhookPayload
	This parameter accepts the Azure Automation-specific $WebhookData.RequestBody content, which contains
	input parameters from Slack. The function parses the query string, and returns a HashTable of key-value
	pairs, that represents the input parameters from a Webhook invocation from Slack.
	
	eg. var1=value1&var2=value2&var3=value3 
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string] $WebhookPayload
	)
	
	$ParamHT = @{ };
	$Params = $WebhookPayload.Split('&');
	
	foreach ($Param in $Params) {
		try {
			$Param = $Param.Split('=');
			$ParamHT.Add($Param[0], [System.Net.WebUtility]::UrlDecode($Param[1]))			
		}
		catch {
			Write-Warning -Message ('Possible null parameter value for {0}' -f $Param[0]);
		}
	}
	
	Write-Output -InputObject $ParamHT;
}

### Invoke the retrieval of Slack parameters

### Example result:
<#
Name                           Value                                                                                    
----                           -----                                                                                    
team_id                        S1L63JMUI                                                                                
user_name                      trevor                                                                                   
channel_id                     BOU20EN7T                                                                                
response_url                   https://hooks.slack.com/commands/S1L63JMUI/22387674759/Cw62aJBtn2E29IBkS1ZkFqiP          
command                        /runbook                                                                                 
text                           list                                                                                         
user_id                        U0L26M71V                                                                                
team_domain                    artofshell
token                          baMLUbHjU32psaPGvQm2sF4j                                                                 
channel_name                   general
#>
$SlackParams = Get-SlackParameter -WebhookPayload $WebhookData.RequestBody;

### For testing, output the list of Slack parameters. Normally not needed for production Runbooks.
#Write-Output -InputObject $SlackParams;
Write-Verbose -Message $SlackParams;

function Send-SlackMessage {
	<#Get-AutomationPSCredential -Name 'AzureAdmin'
	.Synopsis
	This function sens a message to a Slack channel.
	
	.Description
	This function sens a message to a Slack channel. There are several parameters that enable you to customize
	the message that is sent to the channel. For example, you can target the message to a different channel than
	the Slack incoming webhook's default channel. You can also target a specific user with a message. You can also
	customize the emoji and the username that the message comes from.
	
	For more information about incoming webhooks in Slack, check out this URL: https://api.slack.com/incoming-webhooks
	
	.Parameter Message
	The -Message parameter specifies the text of the message that will be sent to the Slack channel.
	
	.Parameter Channel
	The name of the Slack channel that the message should be sent to.
	
	- You can specify a channel, using the syntax: #<channelName>
	- You can target the message at a specific user, using the syntax: @<username>
	
	.Parameter $Emoji
	The emoji that should be displayed for the Slack message. There is an emoji cheat sheet available here:
	http://www.emoji-cheat-sheet.com/
	
	.Parameter Username
	The username that the Slack message will come from. You can customize this with any string value.
	
	.Links
	https://api.slack.com/incoming-webhooks - More information about Slack incoming webhooks
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string] $Message
	  , [Parameter(Mandatory = $false)]
	    [string] $Channel = ''
	  , [Parameter(Mandatory = $false)]
	    [string] $Emoji = ''
	  , [Parameter(Mandatory = $false)]
	    [string] $Username = 'Azure Automation'
	)
	
	### Build the payload for the REST method call
	$RestBody = @{ 
		text = $Message;
		username = $Username;
		icon_emoji = $Emoji;
		}
	
	### Build the command invocation parameters for Splatting on Invoke-RestMethod
	$RestCall = @{
		Body = (ConvertTo-Json -InputObject $RestBody);
		Uri = Get-AutomationVariable -Name SlackTestIncomingWebhook;
		ContentType = 'application/json';
		Method = 'POST';		
	}
	
	### Invoke the REST method call to the Slack service's webhook.
	Invoke-RestMethod @RestCall;
	
	Write-Verbose -Message 'Sent message to Slack service';
}

<####
NOTE:
	The input parameters from Slack were parsed in the earlier call to the Get-SlackParameter function.
	You can re-use the Send-SlackMessage function to send messages to your Slack channel.
	YOUR MAIN LOGIC GOES DOWN HERE.
####>


### This example posts a Slack message with the list of Azure Resource Manager (ARM) Resource Groups
###
### NOTE: This specific example is dependent on a Credential Asset named "AzureAdmin" that has access to your
###       Microsoft Azure subscription. You can safely delete this example, and replace it with your own, that
if ($SlackParams.Text -eq 'armlistgroups') {
    Write-Verbose -Message 'Listing Microsoft Azure Resource Manager (ARM) Resource Groups';
    
    # Authenticate using Azure credentials
    $null = Add-AzAccount -Credential (Get-AutomationPSCredential -Name "AzureAdmin")
    
    # Retrieve and list resource group names
    $resourceGroups = Get-AzResourceGroup | Select-Object -ExpandProperty ResourceGroupName
    Send-SlackMessage -Message ($resourceGroups -join "`n")
    
    return;
}

### test 
if($SlackParams.Text -like 'test'){
	Send-SlackMessage -Message "Hello World"
    return;
}

if($SlackParams.Text -like 'graph'){
    # Add admin account for authentication
    $null = Add-AzAccount -Credential (Get-AutomationPSCredential -Name "AzureAdmin")

    # First ensure the Microsoft.Graph module is installed
    try {
        Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    }
    catch {
        Send-SlackMessage -Message "Error: Microsoft Graph module not installed. Please install Microsoft.Graph module in the Automation Account."
        return
    }

    # Connect to Microsoft Graph
    try {
        Connect-MgGraph -Scopes 'User.ReadWrite.All'
    }
    catch {
        Send-SlackMessage -Message "Error connecting to Entra: $($_.Exception.Message)"
        return
    }
    Send-SlackMessage -Message "Connected to Graph"
}

if ($SlackParams.Text -like 'list_licenses') {
    # Add admin account for authentication
    $null = Add-AzAccount -Credential (Get-AutomationPSCredential -Name "AzureAdmin")
    
    try {
        # Connect to Microsoft Graph
        Connect-MgGraph -Scopes 'Organization.Read.All'
        
        # Get and format license info
        $licenses = Get-MgSubscribedSku | Select-Object @{
            Name='License Name';
            Expression={$_.SkuPartNumber}
        }, @{
            Name='Total Units';
            Expression={$_.PrepaidUnits.Enabled}
        }, @{
            Name='Used Units';
            Expression={$_.ConsumedUnits}
        }, @{
            Name='Available Units';
            Expression={$_.PrepaidUnits.Enabled - $_.ConsumedUnits}
        }
        
        # Format output for Slack
        $licenseInfo = $licenses | ForEach-Object {
            "License: $($_.'License Name')`nTotal: $($_.'Total Units') | Used: $($_.'Used Units') | Available: $($_.'Available Units')`n"
        }
        
        Send-SlackMessage -Message "Available Licenses:`n$($licenseInfo)"
    }
    catch {
        Send-SlackMessage -Message "Error retrieving licenses: $($_.Exception.Message)"
    }
}

### add member to avd 
if ($SlackParams.Text -like 'member*') {
    try {
        $null = Add-AzAccount -Credential (Get-AutomationPSCredential -Name "AzureAdmin") 
        
        $name = $SlackParams.Text -replace 'member\s*', '' 

        $memberId = (Get-AzADUser -UserPrincipalName $name).Id
        $displayname = (Get-AzADUser -UserPrincipalName $name).DisplayName
        
        $gname = "student_users" # this is static can be passed as a value 
        $groupid = (Get-AzADGroup -DisplayName $gname).Id
        Send-SlackMessage -Message ("Group ID found for {0}: {1}" -f $gname, $groupid)
        
        # Initialize member array and retrieve member ID
        $members = @()
        
        if ($memberId) {
            $members += $memberId
            # Add member to the group
            Add-AzADGroupMember -TargetGroupObjectId $groupid -MemberObjectId $members
            Send-SlackMessage -Message ("{0} successfully added to group {1}" -f $displayname, $gname)
        }
        else {
            throw ('User {0} not found in Azure AD' -f $name)
        }
    }
    catch { # error handling 
        Send-SlackMessage -Message ('Error occurred while adding {0} to group {1}: {2}' -f $name, $gname, $PSItem.Exception.Message)
    }
    return;
}


### add entra id member 
if ($SlackParams.Text -like 'new_login*') {
    # Add admin account for authentication
    $null = Add-AzAccount -Credential (Get-AutomationPSCredential -Name "AzureAdmin")
    
    try {
        # Connect to Microsoft Graph
        try {
            Connect-MgGraph -Scopes "User.ReadWrite.All", "Directory.ReadWrite.All"
            Connect-AzureAD
        }
        catch {
            Send-SlackMessage -Message "Error connecting to Entra: $($_.Exception.Message)"
            return
        }

        $displayname = $SlackParams.Text -replace 'new_login\s*', ''
        $userPrincipalName = ($displayName.ToLower() -replace ', ', '' -replace ' ', '') + '@penguincoding.org'
        # Function to check if a user exists
        function Get-UserExistence {
            param (
                [string]$upn
            )
            $user = Get-MgUser -Filter "userPrincipalName eq '$upn'" -ErrorAction SilentlyContinue
            return $user -ne $null
        }

        # Function to generate a unique username if it already exists
        function Get-UniqueUsername {
            param (
                [string]$baseUpn
            )
            $counter = 1
            $newUpn = $baseUpn

            while (Get-UserExistence -upn $newUpn) {
                $newUpn = ($displayName.ToLower() -replace ', ', '' -replace ' ', '') + $counter + '@penguincoding.org'
                $counter++
            }
            return $newUpn
        }

        # Check if the user already exists and generate a unique username if needed
        if (Get-UserExistence -upn $userPrincipalName) {
            $userPrincipalName = Get-UniqueUsername -baseUpn $userPrincipalName
        }

        Send-SlackMessage -Message ("Finalized UPN: {0}" -f $userPrincipalName)

        # Generate a random password function
        function Generate-Password {
            $wordBank = @(
                'ball', 'bear', 'bike', 'bird', 'book', 'cake', 'call', 'card', 'care', 'cats',
                'cook', 'cool', 'desk', 'door', 'draw', 'duck', 'farm', 'fish', 'flag', 'flow',
                'food', 'game', 'gift', 'girl', 'gold', 'good', 'hand', 'help', 'hero', 'home',
                'hope', 'jump', 'kind', 'king', 'kite', 'lamp', 'leaf', 'life', 'lion', 'love',
                'moon', 'nice', 'note', 'park', 'play', 'rain', 'read', 'rock', 'room', 'rose',
                'safe', 'sand', 'seed', 'ship', 'sing', 'snow', 'soil', 'song', 'star', 'stay',
                'sun', 'swim', 'tall', 'team', 'time', 'tree', 'true', 'walk', 'wave', 'wind',
                'wish', 'wood', 'work', 'year', 'zero', 'zoom', 'blue', 'pink', 'gold', 'mint'
            )
            $randomWord = Get-Random -InputObject $wordBank
            $randomNumber = Get-Random -Minimum 1000 -Maximum 9999
            return "$randomWord$randomNumber!"
        }

        # Generate the password
        $GeneratedPass = Generate-Password

        Send-SlackMessage -Message ("Attempting adding account {0} with username {1} and password {2}" -f $displayname, $UserPrincipalName, $GeneratedPass)

        $userParams = @{
            DisplayName = $displayname
            PasswordProfile = @{
                Password = $GeneratedPass
                ForceChangePasswordNextSignIn = $false
                ForceChangePasswordNextSigninWithMfa = $false
            }
            UserPrincipalName = $UserPrincipalName
            AccountEnabled = $true
            MailNickName = ($displayname -replace ' ', '')
        }

        Connect-MgGraph # maybe redundant

        New-MgUser @userParams
        Send-SlackMessage -Message ("Account successfully added attempting license assignment")

        # Update Usage Location (required before assigning a license)
        $id = '6fd2c87f-b296-42f0-b197-1e91e994b900' # this is not the sku id i dont think but its a place holder for right now 
        $license = @{SkuId = $id}
        Update-MgUser -UserId $newUser.Id -UsageLocation "US"            
        Set-MgUserLicense -UserId $user.Id -AddLicenses @($license) -RemoveLicenses @() 
    }
    catch { # error handling 
        Send-SlackMessage -Message ('Error occurred while adding {0} account' -f $displayname, $PSItem.Exception.Message)
    }
}

# New-MgUser_CreateExpanded: Line | 352 | New-MgUser @userParams | ~~~~~~~~~~~~~~~~~~~~~~ | Authentication needed. Please call Connect-MgGraph.