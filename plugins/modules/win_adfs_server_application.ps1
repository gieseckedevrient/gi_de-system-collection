#!powershell

# Copyright: (c) 2023

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.gi_de.system.plugins.module_utils.dependency

$spec = @{
    options = @{
			server_application_name = @{ type = "str";  required = $true }
			application_group_name = @{ type = "str"; }
			redirect_uri = @{ type = "str"; }
			ad_user_principal_name = @{ type = "str"; }
			state = @{ type = "str"; choices = "absent", "present"; default = "present"}
    }
	required_if = @(,@("state", "present", @("application_group_name","redirect_uri","ad_user_principal_name")))
    supports_check_mode = $false
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec, @(Get-GiDeSystemPowershellSpec))

$serverApplicationName = $module.Params.server_application_name
$applicationGroupName = $module.Params.application_group_name
$redirectUri = $module.Params.redirect_uri
$adUserPrincipalName = $module.Params.ad_user_principal_name
$state = $module.Params.state
$adfsversion = $module.Params.adfsversion

# Load ADFS powershell module
try {
  Import-Module -Name ADFS -RequiredVersion $adfsversion
}
catch {
  $module.FailJson("Failed to import ADFS PowerShell module. This module must be available.", $_)
}

function AddOrUpdate-ServerApplication() {
  param
  (
    [parameter(Mandatory = $true)]
    [System.String]
    $ApplicationGroupName,

	[parameter(Mandatory = $true)]
    [System.String]
    $serverApplicationName,

	[parameter(Mandatory = $true)]
    [System.String]
    $RedirectUri,

	[parameter(Mandatory = $true)]
		[System.String]
		$adUserPrincipalName
  )
	$existingServerApplication = Get-AdfsServerApplication -Name $serverApplicationName

	if(-not $existingServerApplication){
		$existingApplicationGroup = Get-AdfsApplicationGroup -ApplicationGroupIdentifier $ApplicationGroupName

		if(-not $existingApplicationGroup){
			$module.FailJson("The application group '$($ApplicationGroupName)' doesn't exist")
		}

		Add-AdfsServerApplication -Name $serverApplicationName -Identifier $RedirectUri -ApplicationGroupIdentifier $ApplicationGroupName -RedirectUri $RedirectUri -ADUserPrincipalName $adUserPrincipalName

		$module.Result.changed = $true
		$module.Result.Msg = "The server application '$($serverApplicationName)' has been created"
		$module.Result.identifier = $RedirectUri
	}else{
		$module.Result.changed = $false
		$module.Result.identifier = $existingServerApplication.Identifier

		$updateParams = @{ TargetName = $serverApplicationName }
		$updateRequired = $false

		if ($existingServerApplication.RedirectUri -ne $RedirectUri -or $existingServerApplication.Identifier -ne $RedirectUri){
			$updateParams.RedirectUri = $RedirectUri
			$updateParams.Identifier = $RedirectUri
			$module.Result.identifier = $RedirectUri
			$updateRequired = $true
		}
		if ($existingServerApplication.ADUserPrincipalName -ne $adUserPrincipalName){
			$updateParams.ADUserPrincipalName = $adUserPrincipalName
			$updateRequired = $true
		}

		if ($updateRequired) {
			Set-AdfsServerApplication @updateParams

			$module.Result.changed = $true
			$module.Result.Msg = "The server application '$($serverApplicationName)' has been updated"
		}
		else {
			$module.Result.Msg = "The server application '$($serverApplicationName)' is already in the desired state"
		}
	}
}

function Remove-ServerApplication() {
  param
  (
    [parameter(Mandatory = $true)]
    [System.String]
    $serverApplicationName
  )
    $existingServerApplication = Get-AdfsServerApplication -Name $serverApplicationName

	if($existingServerApplication)
	{
		Remove-AdfsServerApplication -TargetName $serverApplicationName
		$module.Result.Msg = "The server application '$($serverApplicationName)' has been removed"
		$module.Result.changed = $true
	}else{
		$module.Result.changed = $false
	}
}

if ( -not ($state -eq "absent")) {
	AddOrUpdate-ServerApplication -ApplicationGroupName $applicationGroupName -serverApplicationName $serverApplicationName -RedirectUri $redirectUri -adUserPrincipalName $adUserPrincipalName
}
else
{
	Remove-ServerApplication -serverApplicationName $serverApplicationName
}

$module.ExitJson()