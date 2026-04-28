#!powershell

# Copyright: (c) 2023, Giesecke Devrient

#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
  options             = @{
    cluster = @{ type = "str"; default = "." }
    name    = @{ type = "list"; elements = "str" }
  }
  supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)
$module.Result.exists = $false

# Load powershell module
try {
  Import-Module -Name FailoverClusters
}
catch {
  $module.FailJson("Failed to import FailoverClusters module. You may need to add the Failover Cluster Module for Windows PowerShell Feature.")
}

# Get clustered roles (resource groups)
try {
  if ($module.Params.name) {
    $ClusterGroups = Get-ClusterGroup -Name $module.Params.name -Cluster $module.Params.cluster
  }
  else {
    $ClusterGroups = Get-ClusterGroup -Cluster $module.Params.cluster
  }
}
catch {
  $module.FailJson("Failed to get clustered roles: $($_.Exception.Message)", $_)
}

$module.Result.clustergroup = @($ClusterGroups | ForEach-Object {
    @{
      allowfailback    = [boolean]$_.AutoFailbackType
      cluster          = $_.Cluster.ToString()
      description      = $_.Description
      iscoregroup      = $_.IsCoreGroup
      lockedfrommoving = [boolean]$_.LockedFromMoving
      name             = $_.Name
      state            = $_.State.ToString()
    }
    $module.Result.exists = $true
  })

$module.ExitJson()
