#!powershell

#Requires -Module Ansible.ModuleUtils.Legacy

$ErrorActionPreference = "Stop"

$params = Parse-Args -arguments $args -supports_check_mode $true
$check_mode = Get-AnsibleParam -obj $params -name "_ansible_check_mode" -type "bool" -default $false

# Module control parameters
$state = Get-AnsibleParam -obj $params -name "state" -type "str" -default "present" -validateset "present","query"

$result = @{
  changed = $false
}

# Get existing root key
try {
  $KdsRootKey_obj = Get-KdsRootKey
}
catch {
  $KdsRootKey_obj = $null
}

If ($state -eq 'present') {
  try {
    # If the root key does not exist, create it
    If (-not $KdsRootKey_obj) {
      Add-KdsRootKey –EffectiveTime ((Get-date).AddHours(-10)) -WhatIf:$check_mode
      $result.changed = $true
      If ($check_mode) {
          Exit-Json $result
      }
      $KdsRootKey_obj = Get-KdsRootKey
    }
  }
  catch {
    Fail-Json $result $_.Exception.Message
  }
}

Exit-Json -obj $result
