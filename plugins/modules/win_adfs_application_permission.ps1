#!powershell

# Copyright: (c) 2023

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.gi_de.system.plugins.module_utils.dependency

$spec = @{
    options = @{
        clientApplicationName = @{ type = "str"; required = $true }
        webApiApplicationName = @{ type = "str";  required = $true }
		scopeNames = @{ type = "list"; elements = "str" }
		state = @{ type = "str"; choices = "absent", "present"; default = "present"}
    }
    supports_check_mode = $false
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec, @(Get-GiDeSystemPowershellSpec))

$clientApplicationName = $module.Params.clientApplicationName
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
    $ClientApplicationIdentifier,
	
	[parameter(Mandatory = $true)]
    [System.String]
	$WebApiApplicationIdentifier,

	[parameter(Mandatory = $true)]
    [System.String[]]
	$ScopeNames 

  )
    $existingPermission = Get-AdfsApplicationPermission -ClientRoleIdentifiers $ClientApplicationIdentifier | Where-Object { $_.ServerRoleIdentifier -eq $WebApiApplicationIdentifier }

	if(-not $existingPermission){
        Grant-AdfsApplicationPermission -ClientRoleIdentifier $ClientApplicationIdentifier -ServerRoleIdentifier $WebApiApplicationIdentifier -ScopeNames $ScopeNames
		
		$module.Result.changed = $true
		$module.Result.Msg = "The permission between the client application and the web api application has been added"
	}else{
		$module.Result.changed = $false
	}
}

function Remove-ApplicationPermission() {
  param
  (
    [parameter(Mandatory = $true)]
    [System.String]
    $ClientApplicationIdentifier,
	
	[parameter(Mandatory = $true)]
    [System.String]
	$WebApiApplicationIdentifier 
  )
    $existingPermission = Get-AdfsApplicationPermission -ClientRoleIdentifiers $ClientApplicationIdentifier | Where-Object { $_.ServerRoleIdentifier -eq $WebApiApplicationIdentifier  }

	if($existingPermission)
	{
		Revoke-AdfsApplicationPermission -TargetClientRoleIdentifier $ClientApplicationIdentifier -TargetServerRoleIdentifier $WebApiApplicationIdentifier 
		$module.Result.Msg = "The permission between the client application and the web api application has been removed"
		$module.Result.changed = $true
	}else{
		$module.Result.changed = $false
	}
}

function Get-ClientApplicationIdentifier(){
  param
  (
	[parameter(Mandatory = $true)]
	[System.String]
	$ClientApplicationName
  )
	$existingClientApplication = Get-AdfsNativeClientApplication -Name $ClientApplicationName

	if (-Not $existingClientApplication) {
		$existingClientApplication = Get-AdfsServerApplication -Name $ClientApplicationName
		if(-Not $existingClientApplication){
			$module.FailJson("The client application '$($ClientApplicationName)' doesn't exist.")
		}
	}
	
	return $existingClientApplication.Identifier
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
$clientApplicationIdentifier = Get-ClientApplicationIdentifier -ClientApplicationName $clientApplicationName

if ( -not ($state -eq "absent")) {
	Add-ApplicationPermission -WebApiApplicationIdentifier $webApiApplicationIdentifier -ClientApplicationIdentifier $clientApplicationIdentifier -ScopeNames $scopeNames
}
else
{
	Remove-ApplicationPermission -WebApiApplicationIdentifier $webApiApplicationIdentifier -ClientApplicationIdentifier $clientApplicationIdentifier
}

$module.ExitJson()