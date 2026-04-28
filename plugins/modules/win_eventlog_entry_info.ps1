#!powershell

#AnsibleRequires -CSharpUtil Ansible.Basic

# Copyright: (c) 2025, Giesecke Devrient

#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
  options             = @{
    log             = @{ type = "str" ; required = $false ; default = "Application" }
    entry_type      = @{ type = "list" ; elements = "str";
      choices = "Error", "FailureAudit", "Information", "SuccessAudit", "Warning" ;
      default = @("Error") ;
      required = $false
    }
    source          = @{ type = "list"; elements = "str"; required = $false }
    limit           = @{type = "int" ; required = $false ; default = 5 }
    maxageinminutes = @{type = "int" ; required = $false ; default = 5 }
  }
  supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$log = $module.Params.log
$entry_type = $module.Params.entry_type
$limit = $module.Params.limit
$source = $module.Params.source
$maxageinminutes = $module.Params.maxageinminutes
$module.Result.changed = $false

# prepare the arguments
$params = @{
  "-LogName"   = $log
  "-Newest"    = $limit
  "-Entrytype" = $entry_type
}
# add time range filter
if (0 -ne $maxageinminutes) {
  $now = Get-Date
  $params['-After'] = $now.AddMinutes(-$maxageinminutes)
}

# add argument if filtering on source
if ($null -ne $source) {
  $params['Source'] = $source
}

try {
  # Get eventlog entries
  $events = @(Get-Eventlog @params) #force output as an array even if single result
}
catch {
  $module.FailJson("Failed Get EventLogs. using params $($params)", $_)
}

try {
  $module.Result.events = @() # empty result

  if ($events.Count -gt 0) {
    $module.Result.msg += "$($events.Count) eventlog(s) found"
    foreach ($event in $events) {
      $event_info = @{}
      $event_info.TimeGenerated = $event.TimeGenerated.ToString()
      $event_info.Source = $event.Source
      $event_info.EntryType = $event.EntryType.ToString()
      $event_info.Message = $event.Message
      $event_info.UserName = $event.UserName
      $event_info.EventID = $event.EventID
      # $event_info.Data = $event.Data
      $module.Result.events += $event_info
    }
  }
  else {
    $module.Result.msg += "No eventlog found"
  }
}
catch {
  $module.FailJson("Failed Parsing found events", $_)
}

$module.ExitJson()
