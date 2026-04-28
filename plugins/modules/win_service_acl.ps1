#!powershell

# Copyright: (c) 2023-2023, Giesecke Devrient <sylvain.audie@gi-de.com>

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell Ansible.ModuleUtils.SID
#AnsibleRequires -PowerShell ansible_collections.gi_de.system.plugins.module_utils.dependency

$spec = @{
  options             = @{
    services = @{ type = "list"; elements = "str"; required = $true }
    identity = @{ type = "str"; required = $true }
    rights   = @{
      type     = "list"
      elements = "str"
      choices  = "FullControl", "QueryConfig", "ChangeConfig", "QueryStatus", "EnumerateDependents", "Start",
      "Stop", "PauseContinue", "Interrogate", "UserDefinedControl", "Delete", "ReadControl", "WriteDac", "WriteOwner"
      default  = "QueryConfig", "QueryStatus", "EnumerateDependents", "Start", "Stop", "PauseContinue", "Interrogate", "UserDefinedControl", "ReadControl"
    }
    state    = @{ type = "str"; choices = "present", "absent"; default = "present" }
  }
  supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)
$ErrorActionPreference = "Stop"

$module.Result.changed = $false
$checkmode = $module.CheckMode
$state = $module.Params.state

$Services = $module.Params.services
$Identity = $module.Params.identity
$Rights = $module.Params.rights

# Load powershell module
try {
  Import-Module -Name Carbon -RequiredVersion $module.Params.carbonversion
}
catch {
  $module.FailJson("Failed to import Carbon " + $module.Params.carbonversion + " PowerShell module. This module must be available.")
}

# Test that the user/group is resolvable on the local machine
$SID = Convert-ToSID -account_name $Identity
if (!$SID) {
  $module.FailJson("$User is not a valid user or group on the host machine or domain")
}

$granted = 0
$revoked = 0
foreach ($ServiceName in $Services) {
  # Test that service is present
  $Service = Get-Service -Name $ServiceName
  if ($null -eq $Service) {
    $module.Warn("Service $ServiceName not found, permissions could not be set.")
    continue
  }

  # Get service rights
  $ServicePermission = Get-CServicePermission -Name $ServiceName -Identity $Identity

  if ( -not ($state -eq "absent")) {
    if (($null -eq $ServicePermission) -or
        ([Carbon.Security.ServiceAccessRights]$Rights -ne $ServicePermission.ServiceAccessRights)) {
      $RightsSwitchs = @{}
      $Rights | ForEach-Object {
        $RightsSwitchs[$_] = $true
      }
      if ( -not $checkmode) {
        Grant-CServicePermission -Name $ServiceName -Identity $Identity @RightsSwitchs | Out-Null
      }
      $granted++
      $module.Result.changed = $true
    }
  }
  else {
    if ($null -eq $ServicePermission) {
      if ( -not $checkmode) {
        Revoke-CServicePermission -Name $ServiceName -Identity $Identity
      }
      $revoked++
      $module.Result.changed = $true
    }
  }
}

$module.Result.msg = "$granted permissions granted, $revoked permissions revoked"
$module.ExitJson()
