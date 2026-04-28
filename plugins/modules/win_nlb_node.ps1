#!powershell

# Copyright: (c) 2023, Giesecke Devrient

#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
  options             = @{
    existingnodename      = @{ type = "str"; required = $true }
    existinginterfacename = @{ type = "str"; required = $true }
    newnodename           = @{ type = "str"; required = $true }
    newinterfacename      = @{ type = "str"; required = $true }
    state                 = @{ type = "str"; choices = "absent", "present"; default = "present" }
  }
  supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)
$module.Result.changed = $false
$checkmode = $module.CheckMode
$state = $module.Params.state

$HostName = $module.Params.existingnodename
$InterfaceName = $module.Params.existinginterfacename
$NewNodeName = $module.Params.newnodename
$NewNodeInterface = $module.Params.newinterfacename

function Test-NodePresent() {
  [CmdletBinding()]
  param
  (
    [parameter(Mandatory = $true)]
    [System.String]
    $HostName,

    [parameter(Mandatory = $true)]
    [System.String]
    $InterfaceName,

    [parameter(Mandatory = $true)]
    [System.String]
    $NodeName
  )

  if ((Get-NlbClusterNode @PSBoundParameters -ErrorAction SilentlyContinue).Count -gt 0) {
    return $true
  }
  else {
    return $false
  }
}

function Add-Node() {
  [CmdletBinding(SupportsShouldProcess)]
  [CmdletBinding()]
  param
  (
    [parameter(Mandatory = $true)]
    [System.String]
    $HostName,

    [parameter(Mandatory = $true)]
    [System.String]
    $InterfaceName,

    [parameter(Mandatory = $true)]
    [System.String]
    $NewNodeName,

    [parameter(Mandatory = $true)]
    [System.String]
    $NewNodeInterface
  )

  $module.Debug("Adding Node $NewNodeName with Interface name $NewNodeInterface to cluster on node $HostName with Interface name $InterfaceName")
  if ($PSCmdlet.ShouldProcess($PSBoundParameters)) {
    Add-NlbClusterNode @PSBoundParameters -ErrorAction Stop -Force
  }
}

function Remove-Node() {
  [CmdletBinding(SupportsShouldProcess)]
  [CmdletBinding()]
  param
  (
    [parameter(Mandatory = $true)]
    [System.String]
    $InterfaceName
  )

  if ($PSCmdlet.ShouldProcess($PSBoundParameters)) {
    Remove-NlbClusterNode @PSBoundParameters -ErrorAction Stop -Force
  }
}

# Load SqlServer PowerShell module
try {
  Import-Module -Name NetworkLoadBalancingClusters
}
catch {
  $module.FailJson("Failed to import NetworkLoadBalancingClusters PowerShell module. This module must be available.")
}

if ( -not ($state -eq "absent")) {
  if (-not (Test-NodePresent -HostName $HostName -InterfaceName $InterfaceName -NodeName $NewNodeName)) {
    Add-Node -HostName $HostName -InterfaceName $InterfaceName -NewNodeName $NewNodeName -NewNodeInterface $NewNodeInterface
    $module.Result.changed = $true
  }
}
else {
  if (Test-NodePresent -HostName $HostName -InterfaceName $InterfaceName -NodeName $NewNodeName) {
    if ( -not $checkmode) {
      Remove-Node -InterfaceName $NewNodeInterface
    }
    $module.Result.changed = $true
  }
}

$module.ExitJson()
