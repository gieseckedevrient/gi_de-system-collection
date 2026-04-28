#!powershell

# Copyright: (c) 2023

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.gi_de.system.plugins.module_utils.dependency

$spec = @{
    options = @{
		nativeClientApplicationName = @{ type = "str";  required = $true }
        applicationGroupName = @{ type = "str"; }
        redirectUri = @{ type = "str"; }
		state = @{ type = "str"; choices = "absent", "present"; default = "present"}
    }
	required_if = @(,@("state", "present", @("applicationGroupName","redirectUri")))
    supports_check_mode = $false
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec, @(Get-GiDeSystemPowershellSpec))

$nativeClientApplicationName = $module.Params.nativeClientApplicationName
$applicationGroupName = $module.Params.applicationGroupName
$redirectUri = $module.Params.redirectUri
$state = $module.Params.state
$adfsversion = $module.Params.adfsversion

# Load ADFS powershell module
try {
  Import-Module -Name ADFS -RequiredVersion $adfsversion
}
catch {
  $module.FailJson("Failed to import ADFS PowerShell module. This module must be available.", $_)
}

function AddOrUpdate-NativeClientApplication() {
  param
  (
    [parameter(Mandatory = $true)]
    [System.String]
    $ApplicationGroupName,
	
	[parameter(Mandatory = $true)]
    [System.String]
    $NativeClientApplicationName,
	
	[parameter(Mandatory = $true)]
    [System.String]
    $RedirectUri
  )
	$existingNativeClientApplication = Get-AdfsNativeClientApplication -Name $NativeClientApplicationName

	if(-not $existingNativeClientApplication){
		$existingApplicationGroup = Get-AdfsApplicationGroup -ApplicationGroupIdentifier $ApplicationGroupName

		if(-not $existingApplicationGroup){
			$module.FailJson("The application group '$($ApplicationGroupName)' doesn't exist")
		}
		
		$Identifier = New-Guid
		Add-AdfsNativeClientApplication -Name $NativeClientApplicationName -Identifier $Identifier -ApplicationGroupIdentifier $ApplicationGroupName -RedirectUri $RedirectUri
		
		$module.Result.changed = $true
		$module.Result.Msg = "The native client application '$($NativeClientApplicationName)' has been created"
		$module.Result.identifier = $Identifier
	}elseif ($existingNativeClientApplication.RedirectUri -ne $RedirectUri){
		Set-AdfsNativeClientApplication -TargetName $NativeClientApplicationName -RedirectUri $RedirectUri
		
		$module.Result.changed = $true
		$module.Result.Msg = "The native client application '$($NativeClientApplicationName)' has been updated"
		$module.Result.identifier = $existingNativeClientApplication.Identifier
	}else{
		$module.Result.changed = $false
		$module.Result.identifier = $existingNativeClientApplication.Identifier
	}
}

function Remove-NativeClientApplication() {
  param
  (
    [parameter(Mandatory = $true)]
    [System.String]
    $NativeClientApplicationName
  )
    $existingNativeClientApplication = Get-AdfsNativeClientApplication -Name $NativeClientApplicationName

	if($existingNativeClientApplication)
	{
		Remove-AdfsNativeClientApplication -TargetName $NativeClientApplicationName
		$module.Result.Msg = "The native client application '$($NativeClientApplicationName)' has been removed"
		$module.Result.changed = $true
	}else{
		$module.Result.changed = $false
	}
}

if ( -not ($state -eq "absent")) {
	AddOrUpdate-NativeClientApplication -ApplicationGroupName $applicationGroupName -NativeClientApplicationName $nativeClientApplicationName -RedirectUri $redirectUri
}
else
{
	Remove-NativeClientApplication -NativeClientApplicationName $nativeClientApplicationName
}

$module.ExitJson()