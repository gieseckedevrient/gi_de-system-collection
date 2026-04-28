#!powershell

#Requires -Module Ansible.ModuleUtils.Legacy

$ErrorActionPreference = "Stop"

# This module does not use any module parameters, this avoids pslint complaining
#$params = Parse-Args -arguments $args -supports_check_mode $true

$result = @{
    changed = $false
    ansible_facts = @{
        os_installeduiculture_lcid = ([CultureInfo]::InstalledUICulture).LCID
        os_installeduiculture_name = ([CultureInfo]::InstalledUICulture).Name
        os_installeduiculture_displayname = ([CultureInfo]::InstalledUICulture).DisplayName
    }
}

Exit-Json -obj $result