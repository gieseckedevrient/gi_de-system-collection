#!powershell

# Copyright: (c) 2023

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.gi_de.system.plugins.module_utils.dependency

$spec = @{
    options = @{
        webApiApplicationName = @{ type = "str";  required = $true }
		scopeNames = @{ type = "list"; elements = "str" }
		state = @{ type = "str"; choices = "absent", "present"; default = "present"}
    }
    supports_check_mode = $false
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec, @(Get-GiDeSystemPowershellSpec))

$webApiApplicationName = $module.Params.webApiApplicationName
$scopeNames = $module.Params.scopeNames
$state = $module.Params.state
$adfsversion = $module.Params.adfsversion

# Load ADFS powershell module
try {
  Import-Module -Name ADFS -RequiredVersion $adfsversion
}
catch {
  $module.FailJson("Failed to import ADFS PowerShell module. This module must be available.", $_)
}

function Add-ApplicationPermission() {
  param
  (
	[parameter(Mandatory = $true)]
    [System.String]
	$WebApiApplicationIdentifier,

	[parameter(Mandatory = $true)]
    [System.String[]]
	$ScopeNames
  )
		$existingPermission = Get-AdfsApplicationPermission -ServerRoleIdentifiers $WebApiApplicationIdentifier | Where-Object { $_.ClientRoleIdentifier -eq "AllRegisteredClients" }

		if ($existingPermission) {
			$scopesMatch = (@($ScopeNames | Where-Object { $_ -notin $existingPermission.ScopeNames }).Count -eq 0) -and (@($existingPermission.ScopeNames | Where-Object { $_ -notin $ScopeNames }).Count -eq 0)
			if (-not $scopesMatch) {
				Revoke-AdfsApplicationPermission -TargetIdentifier $existingPermission.ObjectIdentifier
				Grant-AdfsApplicationPermission -ServerRoleIdentifier $WebApiApplicationIdentifier -AllowAllRegisteredClients -ScopeNames $ScopeNames
				$module.Result.changed = $true
				$module.Result.Msg = "The permission scopes have been updated"
			}
			else {
				$module.Result.changed = $false
				$module.Result.Msg = "The permission already exists with the specified scopes for AllRegisteredClients"
			}
		}
		else{
			Grant-AdfsApplicationPermission -ServerRoleIdentifier $WebApiApplicationIdentifier -AllowAllRegisteredClients -ScopeNames $ScopeNames

			$module.Result.changed = $true
			$module.Result.Msg = "The permission between the client application and the web api application has been added"
		}
}

function Remove-ApplicationPermission() {
  param
  (
	[parameter(Mandatory = $true)]
    [System.String]
	$WebApiApplicationIdentifier
  )
    $existingPermission = Get-AdfsApplicationPermission -ServerRoleIdentifiers $WebApiApplicationIdentifier | Where-Object { $_.ClientRoleIdentifier -eq "AllRegisteredClients" }

	if($existingPermission)
	{
		Revoke-AdfsApplicationPermission -TargetIdentifier $existingPermission.ObjectIdentifier
		$module.Result.Msg = "The permission between the client application and the web api application has been removed"
		$module.Result.changed = $true
	}else{
		$module.Result.changed = $false
	}
}

function Get-WebApiApplicationIdentifier(){
  param
  (
	[parameter(Mandatory = $true)]
	[System.String]
	$WebApiApplicationName
  )
	$existingWebApiApplication = Get-AdfsWebApiApplication -Name $WebApiApplicationName

	if (-Not $existingWebApiApplication) {
		$module.FailJson("The web api application '$($WebApiApplicationName)' doesn't exist.")
	}

	return $existingWebApiApplication.Identifier[0]
}

$webApiApplicationIdentifier = Get-WebApiApplicationIdentifier -WebApiApplicationName $webApiApplicationName

if ( -not ($state -eq "absent")) {
	Add-ApplicationPermission -WebApiApplicationIdentifier $webApiApplicationIdentifier -ScopeNames $scopeNames
}
else
{
	Remove-ApplicationPermission -WebApiApplicationIdentifier $webApiApplicationIdentifier
}

$module.ExitJson()