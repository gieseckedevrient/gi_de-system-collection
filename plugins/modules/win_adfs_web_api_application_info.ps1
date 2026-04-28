#!powershell

# Copyright: (c) 2023

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.gi_de.system.plugins.module_utils.dependency

$spec = @{
    options = @{
        webApiApplicationName = @{ type = "str";  required = $true }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec, @(Get-GiDeSystemPowershellSpec))

$webApiApplicationName = $module.Params.webApiApplicationName
$adfsversion = $module.Params.adfsversion

# Load ADFS powershell module
try {
  Import-Module -Name ADFS -RequiredVersion $adfsversion
}
catch {
  $module.FailJson("Failed to import ADFS PowerShell module. This module must be available.", $_)
}

# Get web api application identifier
$existingWebApiApplication = Get-AdfsWebApiApplication -Name $webApiApplicationName

if ($existingWebApiApplication) {
	$module.Result.Msg = "The web api application '$($webApiApplicationName)' has been retrieved."
	$module.Result.identifier = $existingWebApiApplication.Identifier[0]
}else {
	$module.Result.Msg = "The web api application '$($webApiApplicationName)' doesn't exist."
}

$module.ExitJson()