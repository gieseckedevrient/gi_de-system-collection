#!powershell

# Copyright: (c) 2023-2023, Giesecke Devrient <sylvain.audie@gi-de.com>

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell Ansible.ModuleUtils.SID

$spec = @{
  options             = @{
    identity = @{ type = "str"; required = $true }
    state    = @{ type = "str"; choices = "present", "absent"; default = "present" }
  }
  supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)
$ErrorActionPreference = "Stop"

$module.Result.changed = $false
$checkmode = $module.CheckMode
$identity = $module.Params.identity
$state = $module.Params.state

# Get user SID
$userSID = Convert-ToSID -account_name $identity

# Get service manager current permissions
$ScManagerRegistryKey = @{
  Path        = 'HKLM:\SYSTEM\CurrentControlSet\Control\ServiceGroupOrder\Security'
  ErrorAction = 'Stop'
}
$ScManagerSecurityDescriptor = $(
  try {
    New-Object -TypeName System.Security.AccessControl.CommonSecurityDescriptor -ArgumentList (
      $true,
      $false,
      ((Get-ItemProperty -Name Security @ScManagerRegistryKey).Security),
      0
    )
  }
  catch [System.Management.Automation.ItemNotFoundException] {
    New-Object -TypeName System.Security.AccessControl.CommonSecurityDescriptor -ArgumentList (
      $true,
      $false,
      ((& (Get-Command "$($env:SystemRoot)\System32\sc.exe") @('sdshow', 'scmanager'))[1])
    )
  }
  catch {
    $module.FailJson("Failed to read Security in the registry because $($_.Exception.Message)")
  }
)

if (-not ($state -eq "absent")) {
  if ($userSID -notin $ScManagerSecurityDescriptor.DiscretionaryAcl.SecurityIdentifier) {
    # Add Access
    try {
      $ScManagerSecurityDescriptor.DiscretionaryAcl.AddAccess(
        [System.Security.AccessControl.AccessControlType]::Allow,
        [System.Security.Principal.SecurityIdentifier]$userSID,
        0x20015, # CC - SC_MANAGER_CONNECT, LC - SC_MANAGER_ENUMERATE_SERVICE, RP - SC_MANAGER_QUERY_LOCK_STATUS, RC - STANDARD_RIGHTS_READ
        0,
        0
      )
    }
    catch {
      $module.FailJson("Failed to add access because $($_.Exception.Message)")
    }
    # Commit changes
    try {
      if (-not $checkmode) {
        $Sddl = $ScManagerSecurityDescriptor.GetSddlForm([System.Security.AccessControl.AccessControlSections]::All)
        (& (Get-Command "$($env:SystemRoot)\System32\sc.exe") @('sdset', 'scmanager', "$($Sddl)")) | Out-Null
      }
    }
    catch {
      $module.FailJson("Failed to set Security in the registry because $($_.Exception.Message)")
    }
    $module.Result.changed = $true
  }
}
else {
  if ($userSID -in $ScManagerSecurityDescriptor.DiscretionaryAcl.SecurityIdentifier) {
    $ScManagerSecurityDescriptor.DiscretionaryAcl | Where-Object { $_.SecurityIdentifier.Value -eq $userSID } | ForEach-Object {
      # Remove Access
      try {
        $ScManagerSecurityDescriptor.DiscretionaryAcl.RemoveAccessSpecific(
          $_.AceType,
          $_.SecurityIdentifier,
          $_.AccessMask,
          0,
          0
        )
      }
      catch {
        $module.FailJson("Failed to remove access because $($_.Exception.Message)")
      }
    }
    # Commit changes
    try {
      if (-not $checkmode) {
        $Sddl = $ScManagerSecurityDescriptor.GetSddlForm([System.Security.AccessControl.AccessControlSections]::All)
        (& (Get-Command "$($env:SystemRoot)\System32\sc.exe") @('sdset', 'scmanager', "$($Sddl)")) | Out-Null
      }
    }
    catch {
      $module.FailJson("Failed to set Security in the registry because $($_.Exception.Message)")
    }
    $module.Result.changed = $true
  }
}

$module.ExitJson()
