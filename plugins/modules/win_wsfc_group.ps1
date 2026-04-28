#!powershell

# Copyright: (c) 2023, Giesecke Devrient

#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
  options             = @{
    cluster = @{ type = "str"; default = "." }
    name    = @{ type = "list"; elements = "str"; required = $true }
    state   = @{ type = "str"; choices = "started", "stopped", "restarted", "moved"; default = "moved" }
    node    = @{ type = "str" }
  }
  supports_check_mode = $false
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)
$module.Result.changed = $false

# Load powershell module
try {
  Import-Module -Name FailoverClusters
}
catch {
  $module.FailJson("Failed to import FailoverClusters module. You may need to add the Failover Cluster Module for Windows PowerShell Feature.")
}

# Get clustered roles (resource groups)
try {
  $ClusterGroups = Get-ClusterGroup -Name $module.Params.name -Cluster $module.Params.cluster
}
catch {
  $module.FailJson("Failed to get clustered roles: $($_.Exception.Message)", $_)
}

# Manage clustered roles (resource groups)
switch ($module.Params.state) {
  "started" {
    try {
      $ClusterGroups | ForEach-Object {
        if ($_.State -ne "Online") {
          Start-ClusterGroup -InputObject $_ -Cluster $module.Params.cluster | Out-Null
          $module.Result.changed = $true
        }
      }
    }
    catch {
      $module.FailJson("Failed to start clustered roles: $($_.Exception.Message)", $_)
    }
    Break
  }
  "stopped" {
    try {
      $ClusterGroups | ForEach-Object {
        if ($_.State -ne "Offline") {
          Stop-ClusterGroup -InputObject $_ -Cluster $module.Params.cluster | Out-Null
          $module.Result.changed = $true
        }
      }
    }
    catch {
      $module.FailJson("Failed to stop clustered roles: $($_.Exception.Message)", $_)
    }
    Break
  }
  "restarted" {
    try {
      $ClusterGroups | Stop-ClusterGroup -Cluster $module.Params.cluster | Out-Null
      $ClusterGroups | Start-ClusterGroup -Cluster $module.Params.cluster | Out-Null
      $module.Result.changed = $true
    }
    catch {
      $module.FailJson("Failed to restart clustered roles: $($_.Exception.Message)", $_)
    }
    Break
  }
  "moved" {
    try {
      $ClusterGroups | ForEach-Object {
        if ($module.Params.node -and ($_.OwnerNode -ne $module.Params.node)) {
          Move-ClusterGroup -InputObject $_ -Cluster $module.Params.cluster -Node $module.Params.node | Out-Null
          $module.Result.changed = $true
        }
        else {
          Move-ClusterGroup -InputObject $_ -Cluster $module.Params.cluster | Out-Null
          $module.Result.changed = $true
        }
      }
    }
    catch {
      $module.FailJson("Failed to move clustered roles: $($_.Exception.Message)", $_)
    }
    Break
  }
}

$module.ExitJson()
