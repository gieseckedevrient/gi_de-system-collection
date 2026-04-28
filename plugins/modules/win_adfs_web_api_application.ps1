#!powershell

# Copyright: (c) 2023

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.gi_de.system.plugins.module_utils.dependency

$spec = @{
    options = @{
		webApiApplicationName = @{ type = "str";  required = $true }
		identifier = @{ type = "str"; }
        applicationGroupName = @{ type = "str"; }
		accessControlPolicyName = @{ type = "str"; }
		tokenLifetime = @{ type = "int"; default = 15 }
		state = @{ type = "str"; choices = "absent", "present"; default = "present"}
		passNameAndGroupClaim = @{ type = "bool"; default = $true }
    }
	required_if = @(,@("state", "present", @("applicationGroupName")))
    supports_check_mode = $false
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec, @(Get-GiDeSystemPowershellSpec))
$module.Result.changed = $false

$webApiApplicationName = $module.Params.webApiApplicationName
$identifier = $module.Params.identifier
$applicationGroupName = $module.Params.applicationGroupName
$accessControlPolicyName = $module.Params.accessControlPolicyName
$tokenLifetime = $module.Params.tokenLifetime
$state = $module.Params.state
$adfsversion = $module.Params.adfsversion
$passNameAndGroupClaim = $module.Params.passNameAndGroupClaim

$passNameAndGroupClaimRule = @"
@RuleTemplate = "PassThroughClaims"
@RuleName = "Pass name"
c:[Type == "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"]
=> issue(claim = c);

@RuleTemplate = "LdapClaims"
@RuleName = "Pass Group Names"
c:[Type == "http://schemas.microsoft.com/ws/2008/06/identity/claims/windowsaccountname", Issuer == "AD AUTHORITY"]
 => issue(store = "Active Directory", types = ("http://schemas.xmlsoap.org/claims/Group"), query = ";tokenGroups;{0}", param = c.Value);
"@

# Load ADFS powershell module
try {
  Import-Module -Name ADFS -RequiredVersion $adfsversion
}
catch {
  $module.FailJson("Failed to import ADFS PowerShell module. This module must be available.", $_)
}

function AddOrUpdate-WebApiApplication() {
  param
  (
	[parameter(Mandatory = $true)]
    [System.String]
    $Identifier,

    [parameter(Mandatory = $true)]
    [System.String]
    $ApplicationGroupName,
	
	[parameter(Mandatory = $true)]
    [System.String]
    $WebApiApplicationName,

	[parameter(Mandatory = $true)]
    [System.String]
    $AccessControlPolicyName,

	[parameter(Mandatory = $true)]
    [System.Int32]
    $TokenLifetime,

	[Parameter(Mandatory = $false)]
	[System.Boolean]
	$PassNameAndGroupClaim = $true
  )
  	$existingWebApiApplication = Get-AdfsWebApiApplication -Name $WebApiApplicationName

	if(-not $existingWebApiApplication){
		$existingApplicationGroup = Get-AdfsApplicationGroup -ApplicationGroupIdentifier $ApplicationGroupName

		if(-not $existingApplicationGroup){
			$module.FailJson("The application group '$($ApplicationGroupName)' doesn't exist")
		}
		
		Add-AdfsWebApiApplication -Name $WebApiApplicationName -Identifier $Identifier -ApplicationGroupIdentifier $ApplicationGroupName -AccessControlPolicyName $AccessControlPolicyName
		Set-AdfsWebApiApplication -TokenLifetime $TokenLifetime -TargetIdentifier $Identifier

		if($PassNameAndGroupClaim) {
			Set-AdfsWebApiApplication -TargetIdentifier $Identifier -IssuanceTransformRules $passNameAndGroupClaimRule
		}

		$module.Result.changed = $true
		$module.Result.Msg = "The web api application '$($WebApiApplicationName)' has been created"
		$module.Result.identifier = $Identifier
	}else{
		$module.Result.identifier = $existingWebApiApplication.Identifier[0]

		if($existingWebApiApplication.TokenLifeTime -ne $TokenLifetime -or $existingWebApiApplication.AccessControlPolicyName -ne $AccessControlPolicyName){
			Set-AdfsWebApiApplication -TokenLifetime $TokenLifetime -AccessControlPolicyName $AccessControlPolicyName -TargetIdentifier $Identifier 

			$module.Result.changed = $true
			$module.Result.Msg = "The web api application '$($WebApiApplicationName)' has been updated"
		}

		if($PassNameAndGroupClaim -and (-not $existingWebApiApplication.IssuanceTransformRules.Contains("Pass name") -or -not $existingWebApiApplication.IssuanceTransformRules.Contains("Pass Group Names"))){
			Set-AdfsWebApiApplication -TargetIdentifier $Identifier -IssuanceTransformRules $passNameAndGroupClaimRule

			$module.Result.changed = $true
			$module.Result.Msg = "The web api application '$($WebApiApplicationName)' has been updated"
		}
	}
}

function Remove-WebApiApplication() {
  param
  (
    [parameter(Mandatory = $true)]
    [System.String]
    $WebApiApplicationName
  )
    $existingWebApiApplication = Get-AdfsWebApiApplication -Name $WebApiApplicationName

	if($existingWebApiApplication)
	{
		Remove-AdfsWebApiApplication -TargetName $WebApiApplicationName
		$module.Result.Msg = "The web api application '$($WebApiApplicationName)' has been removed"
		$module.Result.changed = $true
	}
}

if ( -not ($state -eq "absent")) {
	AddOrUpdate-WebApiApplication -Identifier $identifier -ApplicationGroupName $applicationGroupName -WebApiApplicationName $webApiApplicationName -AccessControlPolicyName $accessControlPolicyName -TokenLifeTime $tokenLifetime -PassNameAndGroupClaim $passNameAndGroupClaim
}
else
{
	Remove-WebApiApplication -WebApiApplicationName $webApiApplicationName
}

$module.ExitJson()