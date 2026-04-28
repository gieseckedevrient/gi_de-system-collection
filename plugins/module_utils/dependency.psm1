# Copyright: (c) 2019, Giesecke Devrient <sylvain.audie@gi-de.com>

Function Get-GiDeSystemPowershellSpec {
  <#
  .SYNOPSIS
  Used by modules to get the argument spec fragment for AnsibleModule.

  .EXAMPLES
  $spec = @{
    options = @{}
  }
  $module = [Ansible.Basic.AnsibleModule]::Create($args, $spec, @(Get-AnsibleWindowsWebRequestSpec))

  .NOTES
  Todo get version from dependency.yml
  #>
  @{
    options = @{
      carbonversion = @{ type = "str"; default = "2.15.1" } # renovate: datasource=powershell depName=Carbon
      adfsversion = @{ type = "str"; default = "1.0.0.0" } # renovate: datasource=powershell depName=ADFS
    }
  }
}

$exportMembers = @{
  Function = 'Get-GiDeSystemPowershellSpec'
}

Export-ModuleMember @exportMembers
