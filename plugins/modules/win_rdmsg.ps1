#!powershell

# Copyright: (c) 2023, Giesecke Devrient

#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
  options             = @{
    title       = @{ type = "str" ; required = $true }
    msg         = @{ type = "str"; default = "" }
    graceperiod = @{ type = "int"; default = 45 }
  }
  supports_check_mode = $true
}


$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)
$checkmode = $module.CheckMode
$module.Result.changed = $false
$hostname = [System.NET.DNS]::GetHostByName('').HostName
$MessageSubject = $module.Params.title
$MessageBody = $module.Params.msg
$GraceWaitingTime = $module.Params.graceperiod #in s

# Load RemoteDesktop powershell module
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

  # notify active sessions about shutoff
  $ActiveSessions = New-RdpSessionTable
  $ActiveSessions = $RDPDiscSessions | Where-Object { $_.STATE -eq 'Active' }

  if ($ActiveSessions.Rows.Count -eq 0) {
    $module.Result.Msg = "No active session found"
  }
  else {
    $module.Result.changed = $true
    $loggedinUsers = ""
    foreach ($row in $ActiveSessions) {
      if ( -not $checkmode) {
        Send-RdUSerMessage -MessageTitle $MessageSubject -MessageBody $MessageBody -HostServer $row.Item("COMPUTERNAME") -UnifiedSessionID $row.Item("ID")
      }
      $loggedinUsers += $row.Item("USERNAME") + " "
    }
    $module.Result.Msg = "$($ActiveSessions.Rows.Count) active sessions notified: Users ($($loggedinUsers))"
    if ( -not $checkmode) {
      Start-Sleep -s $GraceWaitingTime
    }
  }
}
catch {
  $module.FailJson("Failed to message to sessions : $($_.Exception.Message)")
}

$module.ExitJson()
