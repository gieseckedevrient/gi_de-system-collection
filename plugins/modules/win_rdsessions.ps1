#!powershell

# Copyright: (c) 2019-2023, Giesecke Devrient

#AnsibleRequires -CSharpUtil Ansible.Basic

$ErrorActionPreference = "Stop"

$spec = @{
  options             = @{}
  supports_check_mode = $true
}
$checkmode = $module.CheckMode
$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)
$hostname = [System.NET.DNS]::GetHostByName('').HostName
$module.Result.changed = $false

# Load sqlps powershell module
try {
  Import-Module -Name RemoteDesktop
}
catch {
  $module.FailJson("Failed to import RemoteDesktop module. This module must be available.", $_)
}
# Run the sql script
function New-RdpSessionTable() {
  $RDPSessionTable = New-Object System.Data.DataTable("RDPSessions")
  "COMPUTERNAME", "USERNAME", "ID", "STATE" | ForEach-Object {
    $Col = New-Object System.Data.DataColumn $_
    $RDPSessionTable.Columns.Add($Col)
  }
  return , $RDPSessionTable
}
##
function Get-RemoteRdpSession {
  <#
  .SYNOPSIS
      This function is a simple wrapper of query session / qwinsta and returs a DataTable Objects

  .DESCRIPTION
      This function is a simple wrapper of query session / qwinsta and returs a DataTable Objects

  .PARAMETER ComputerName
      ComputerName parameter is required to specify a list of computers to query

  .PARAMETER State
      State parameter is optional and can be set to "ACTIVE" or "DISC". If not
      used both ACTIVE and DISC connections will be returned.

  .EXAMPLE
      Get-RemoteRdpSession  -computername $(Get-AdComputer -filter * | select-object -exp name )

  .EXAMPLE
      Get-RemoteRdpSession  -computername ("server1", "server2") -state DISC
  #>

  [CmdletBinding()]

  [OutputType([int])]
  Param
  (
    [Parameter(Mandatory = $true,
      ValueFromPipelineByPropertyName = $true,
      Position = 0)]
    [string]
    $computername,

    [Parameter(Mandatory = $false, Position = 1 )]
    [ValidateSet("Active", "Disc")]
    [string]
    $state
  )
  Begin {
    $tab = New-RdpSessionTable
  }
  Process {

    $result = query session /server:$hostname
    $rows = $result -split "`n"
    foreach ($row in $rows) {
      if ($state) {
        $regex = $state
      }
      else {
        $regex = "Disc|Active"
      }

      if ($row -NotMatch "services|console" -and $row -match $regex) {
        $session = $($row -Replace ' {2,}', ',').split(',')
        $newRow = $tab.NewRow()
        $newRow["COMPUTERNAME"] = $hostname
        $newRow["USERNAME"] = $session[1]
        $newRow["ID"] = $session[2]
        $newRow["STATE"] = $session[3]
        $tab.Rows.Add($newRow)
      }
    }
  }
  End {
    return $tab
  }
}

try {
  $RDPDiscSessions = Get-RemoteRdpSession -computername $hostname
  if ($RDPDiscSessions.Rows.Count -eq 0) {
    $module.Result.Msg = "No session found"
  }
  else {
    $module.Result.changed = $true
    $sessionsUsers = ""
    #Disconnet all sessions
    foreach ($row in $RDPDiscSessions) {
      if ( -not $checkmode) {
        Invoke-RDUserLogoff -UnifiedSessionID $row.Item("ID") -HostServer $row.Item("COMPUTERNAME") -Force
      }
      $sessionsUsers += $row.Item("USERNAME") + " "
    }
    $module.Result.Msg = "$($RDPDiscSessions.Rows.Count) sessions logged off: Users ($($sessionsUsers))"
  }
}
catch {
  $module.FailJson("Failed to disconnect sessions : $($_.Exception.Message)")
}

$module.ExitJson()
