#!powershell

# Copyright: (c) 2023, Giesecke Devrient

#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
  options             = @{
    clustername           = @{ type = "str"; required = $true }
    clusterip             = @{ type = "str"; required = $true }
    clustersubnetmask     = @{ type = "str"; required = $true }
    dedicatedip           = @{ type = "str" }
    dedicatedipsubnetmask = @{ type = "str" }
    interfacename         = @{ type = "str"; required = $true }
    operationmode         = @{ type = "str"; choices = "IGMPMULTICAST", "MULTICAST", "UNICAST"; default = "MULTICAST" }
    state                 = @{ type = "str"; choices = "absent", "present"; default = "present" }
  }
  supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)
$module.Result.changed = $false
$checkmode = $module.CheckMode
$state = $module.Params.state

$InterfaceName = $module.Params.interfacename
$ClusterName = $module.Params.clustername
$ClusterPrimaryIP = $module.Params.clusterip
$SubnetMask = $module.Params.clustersubnetmask
$DedicatedIP = $module.Params.dedicatedip
$DedicatedIPSubnetMask = $module.Params.dedicatedipsubnetmask
$OperationMode = $module.Params.operationmode

function Test-ClusterPresent() {
  [CmdletBinding()]
  param
  (
    [parameter(Mandatory = $true)]
    [System.String]
    $InterfaceName
  )

  if ((Get-NlbCluster @PSBoundParameters -ErrorAction SilentlyContinue).Count -gt 0) {
    return $true
  }
  else {
    return $false
  }
}

function Test-ClusterUpToDate() {
  [CmdletBinding()]
  param
  (
    [parameter(Mandatory = $true)]
    [System.String]
    $InterfaceName,

    [parameter(Mandatory = $true)]
    [System.String]
    $ClusterPrimaryIP,

    [parameter(Mandatory = $true)]
    [System.String]
    $Name,

    [parameter(Mandatory = $true)]
    [System.String]
    [ValidateSet("IGMPMULTICAST", "MULTICAST", "UNICAST")]
    $OperationMode
  )

  $RequestedConfiguration = [PSCustomObject]@{
    "Name"             = $Name
    "ClusterIPAddress" = $ClusterPrimaryIP
    "OperationMode"    = $OperationMode.ToUpper()
  }
  $CurrentConfiguration = Get-NlbCluster -InterfaceName $InterfaceName

  if (-not (Compare-Object -ReferenceObject $RequestedConfiguration -DifferenceObject $CurrentConfiguration -Property Name, ClusterIPAddress, OperationMode)) {
    return $true
  }
  else {
    return $false
  }
}

function Add-Cluster() {
  [CmdletBinding(SupportsShouldProcess)]
  [CmdletBinding()]
  param
  (
    [parameter(Mandatory = $true)]
    [System.String]
    $ClusterName,

    [parameter(Mandatory = $true)]
    [System.String]
    $ClusterPrimaryIP,

    [parameter(Mandatory = $true)]
    [System.String]
    $InterfaceName,

    [parameter(Mandatory = $true)]
    [System.String]
    $SubnetMask,

    [parameter(Mandatory = $true)]
    [System.String]
    [ValidateSet("IGMPMULTICAST", "MULTICAST", "UNICAST")]
    $OperationMode,

    [parameter(Mandatory = $false)]
    [System.String]
    $DedicatedIP,

    [parameter(Mandatory = $false)]
    [System.String]
    $DedicatedIPSubnetMask
  )

  $module.Debug("Creating Cluster $Clustername with IP $ClusterPrimaryIP on Interface name: $InterfaceName and Subnet mask: $SubnetMask")
  if ($PSCmdlet.ShouldProcess($PSBoundParameters)) {
    New-NlbCluster @PSBoundParameters -ErrorAction Stop -Force
  }
}

function Update-Cluster() {
  [CmdletBinding(SupportsShouldProcess)]
  [CmdletBinding()]
  param
  (
    [parameter(Mandatory = $true)]
    [System.String]
    $InterfaceName,

    [parameter(Mandatory = $true)]
    [System.String]
    $ClusterPrimaryIP,

    [parameter(Mandatory = $true)]
    [System.String]
    $Name,

    [parameter(Mandatory = $true)]
    [System.String]
    [ValidateSet("IGMPMULTICAST", "MULTICAST", "UNICAST")]
    $OperationMode
  )

  if ($PSCmdlet.ShouldProcess($PSBoundParameters)) {
    Set-NlbCluster @PSBoundParameters -ErrorAction Stop
  }
}

function Remove-Cluster() {
  [CmdletBinding(SupportsShouldProcess)]
  [CmdletBinding()]
  param
  (
    [parameter(Mandatory = $true)]
    [System.String]
    $InterfaceName
  )

  if ($PSCmdlet.ShouldProcess($PSBoundParameters)) {
    Remove-NlbCluster @PSBoundParameters -ErrorAction Stop -Force
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
  if (Test-ClusterPresent -InterfaceName $InterfaceName) {
    if ( -not (Test-ClusterUpToDate -InterfaceName $InterfaceName -ClusterPrimaryIP $ClusterPrimaryIP -Name $ClusterName -OperationMode $OperationMode)) {
      if ( -not $checkmode) {
        Update-Cluster -InterfaceName $InterfaceName -ClusterPrimaryIP $ClusterPrimaryIP -Name $ClusterName -OperationMode $OperationMode
      }
      $module.Result.changed = $true
    }
  }
  else {
    if (($null -eq $DedicatedIP) -and ($null -eq $DedicatedIPSubnetMask)) {
      Add-Cluster -ClusterName $ClusterName -ClusterPrimaryIP $ClusterPrimaryIP -InterfaceName $InterfaceName -SubnetMask $SubnetMask -OperationMode $OperationMode
    }
    else {
      Add-Cluster -ClusterName $ClusterName -ClusterPrimaryIP $ClusterPrimaryIP -InterfaceName $InterfaceName -SubnetMask $SubnetMask -OperationMode $OperationMode -DedicatedIP $DedicatedIP -DedicatedIPSubnetMask $DedicatedIPSubnetMask
    }
    $module.Result.changed = $true
  }
}
else {
  if (Test-ClusterPresent -InterfaceName $InterfaceName) {
    if ( -not $checkmode) {
      Remove-Cluster -InterfaceName $InterfaceName
    }
    $module.Result.changed = $true
  }
}

$module.ExitJson()
