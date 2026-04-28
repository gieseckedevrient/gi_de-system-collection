#!powershell

# Copyright: (c) 2020-2022, Giesecke Devrient <sylvain.audie@gi-de.com>

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.gi_de.system.plugins.module_utils.dependency

$spec = @{
  options = @{
      url = @{ type = "str"; required = $true }
      principal = @{ type = "str" }
      permission = @{ type = "str"; default = "Listen"; choices = @("Listen", "Delegate", "ListenAndDelegate") }
      state = @{ type = "str"; default = "present"; choices = @("present", "absent", "query") }
  }
  supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec, @(Get-GiDeSystemPowershellSpec))
$module.Result.changed = $false

$Url = $module.Params.url
$Principal = $module.Params.principal
$Permission = $module.Params.permission
$state = $module.Params.state
$carbonversion = $module.Params.carbonversion

# Load powershell module
try {
  Import-Module -Name Carbon -RequiredVersion $carbonversion
}
catch {
  $module.FailJson("Failed to import Carbon PowerShell module. This module must be available.", $_)
}

# Parameter validation
If (($state -eq "present") -and (($null -eq $Principal) -or ($null -eq $Permission))) {
  $module.FailJson("When adding permission the following parameter must be set : Principal or Permission")
}
If (($state -eq "absent") -and ($null -eq $Principal)) {
  $module.FailJson("When removing permission the following parameter must be set : Principal")
}

# Get existing url acl
try {
  $HttpUrlAcl_obj = Get-CHttpUrlAcl -Url $Url
}
catch {
  $HttpUrlAcl_obj = $null
}

If ($state -eq 'present') {
  try {
    # If the url acl does not exist, create it
    If (-not $HttpUrlAcl_obj) {
      If (-not $check_mode) {
        Grant-CHttpUrlPermission -Url $Url -Principal $Principal -Permission $Permission
      }
      $module.Result.changed = $true
      If ($check_mode) {
          $module.ExitJson()
      }
      $HttpUrlAcl_obj = Get-CHttpUrlAcl -Url $Url
    }
    else {
    # url acl already exists
        $user_found =  $false
        $user_with_right_permission = $false
        foreach ($acl in $HttpUrlAcl_obj.Access)
        {
            if($acl.IdentityReference -eq $Principal){
            $user_found = $true
                if($acl.HttpUrlAccessRights -eq $Permission){
                $user_with_right_permission = $true
                }
            }
        }
        if(-not ($user_with_right_permission) -or -not($user_found)){
          $module.Result.changed = $true
          $module.Result.msg= "user ACL added or changed"
          If ($check_mode) {
              $module.ExitJson()
          }
            Grant-CHttpUrlPermission -Url $Url -Principal $Principal -Permission $Permission

        }
    }
  }
  catch {
    $module.FailJson("Failed to run Grant-CHttpUrlPermission", $_)
  }
} ElseIf ($state -eq 'absent') {
  # Ensure url acl does not exist
  try {
      If ($HttpUrlAcl_obj) {
        $user_found =  $false
        foreach ($acl in $HttpUrlAcl_obj.Access)
        {
            if($acl.IdentityReference -eq $Principal){
            $user_found = $true
            }
        }

        if($user_found){
          $module.Result.changed = $true
          $module.Result.msg= "user ACL removed"
          If ($check_mode) {
              $module.ExitJson()
          }
            Revoke-CHttpUrlPermission -Url $Url -Principal $Principal
        }
        $HttpUrlAcl_obj = $null
      }
  }
  catch {
      $module.FailJson("Failed to run Revoke-CHttpUrlPermission", $_)
  }
}

$module.ExitJson()
