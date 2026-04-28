#!powershell

# Copyright: (c) 2023

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.gi_de.system.plugins.module_utils.dependency

$spec = @{
    options = @{
        applicationGroupName = @{ type = "str"; required = $true }
		state = @{ type = "str"; choices = "absent", "present"; default = "present"}
    }
    supports_check_mode = $false
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec, @(Get-GiDeSystemPowershellSpec))

$applicationGroupName = $module.Params.applicationGroupName
$state = $module.Params.state
$adfsversion = $module.Params.adfsversion

# Load ADFS powershell module
try {
  Import-Module -Name ADFS -RequiredVersion $adfsversion
}
catch {
  $module.FailJson("Failed to import ADFS PowerShell module. This module must be available.", $_)
}

function Add-ApplicationGroup() {
  param
  (
    [parameter(Mandatory = $true)]
    [System.String]
    $ApplicationGroupName
  )
  	$existingApplicationGroup = Get-AdfsApplicationGroup -ApplicationGroupIdentifier $ApplicationGroupName
	if(-not $existingApplicationGroup){
		New-AdfsApplicationGroup -Name $ApplicationGroupName -ApplicationGroupIdentifier $ApplicationGroupName
		$module.Result.Msg = "The application group '$($ApplicationGroupName)' has been created"
		$module.Result.changed = $true
	}else{
		$module.Result.changed = $false
	}
}

function Remove-ApplicationGroup() {
  param
  (
    [parameter(Mandatory = $true)]
    [System.String]
    $ApplicationGroupName
  )
	$existingApplicationGroup = Get-AdfsApplicationGroup -ApplicationGroupIdentifier $applicationGroupName
	if($existingApplicationGroup){
		Remove-AdfsApplicationGroup -TargetName $ApplicationGroupName
		$module.Result.Msg = "The application group '$($ApplicationGroupName)' has been removed"
		$module.Result.changed = $true
	}else{
		$module.Result.changed = $false
	}
}

if ( -not ($state -eq "absent")) {
	Add-ApplicationGroup -ApplicationGroupName $applicationGroupName
}
else
{
	Remove-ApplicationGroup -ApplicationGroupName $applicationGroupName
}

$module.ExitJson()