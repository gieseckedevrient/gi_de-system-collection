#!powershell

# Copyright: (c) 2023

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.gi_de.system.plugins.module_utils.dependency

$spec = @{
    options = @{
        hostName = @{ type = "str";  required = $true }
		state = @{ type = "str"; choices = "absent", "present"; default = "present"}
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec, @(Get-GiDeSystemPowershellSpec))

$hostName = $module.Params.hostName
$state = $module.Params.state
$adfsversion = $module.Params.adfsversion

# Load ADFS powershell module
try {
  Import-Module -Name ADFS -RequiredVersion $adfsversion
}
catch {
  $module.FailJson("Failed to import ADFS PowerShell module. This module must be available.", $_)
}

$corsTrustedOrigins = (Get-AdfsResponseHeaders).CORSTrustedOrigins

function Add-CorsTrustedOrigin() {
  param
  (
    [parameter(Mandatory = $true)]
    [System.String]
    $HostName,

    [parameter(Mandatory = $false)]
    $CORSTrustedOrigins
  )
    if(($CORSTrustedOrigins -notcontains $HostName)){
        $CORSTrustedOrigins += $HostName

        Set-AdfsResponseHeaders -EnableCORS $true
        Set-AdfsResponseHeaders -CORSTrustedOrigins $CORSTrustedOrigins

        $module.Result.changed = $true
        $module.Result.Msg = "The host name '$($HostName)' has been added from CORS trusted origins"
    }else{
        $module.Result.changed = $false
    }
}

function Remove-CorsTrustedOrigin() {
  param
  (
    [parameter(Mandatory = $true)]
    [System.String]
    $HostName,

    [parameter(Mandatory = $false)]
    $CORSTrustedOrigins
  )
    if($CORSTrustedOrigins -contains $HostName){
        $CORSTrustedOrigins = $CORSTrustedOrigins | Where-Object { $_ -ne $HostName }

        if($CORSTrustedOrigins.Count -eq 0){
          Set-AdfsResponseHeaders -EnableCORS $false
          $CORSTrustedOrigins = New-Object 'System.Collections.Generic.List[string]'
          Set-AdfsResponseHeaders -CORSTrustedOrigins $CORSTrustedOrigins
        }else{
          Set-AdfsResponseHeaders -CORSTrustedOrigins $CORSTrustedOrigins
        }

        $module.Result.changed = $true
        $module.Result.Msg = "The host name '$($HostName)' has been removed from CORS trusted origins"
    }else{
        $module.Result.changed = $false
    }
}

if($state -eq "absent")
{
    Remove-CorsTrustedOrigin -HostName $hostName -CORSTrustedOrigins $corsTrustedOrigins
}else{
    Add-CorsTrustedOrigin -HostName $hostName -CORSTrustedOrigins $corsTrustedOrigins
}

$module.ExitJson()
