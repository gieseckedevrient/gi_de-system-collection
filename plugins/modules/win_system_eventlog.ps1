#!powershell

# Copyright: (c) 2024

#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
    options = @{
        name = @{ type='str'; required=$true }
        state = @{ type = "str"; choices = "disable", "enable"; default = "enable"}
    }
    supports_check_mode = $false
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)
$module.Result.changed = $false

$eventLogName = $module.Params.name
$state = $module.Params.state

function Enable-SystemEventLog() {
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $EventLogName
    )

    try {
        $SystemEventLogList = [System.Array](Get-WinEvent -ListLog $EventLogName -ErrorAction SilentlyContinue)
    } catch {
        $module.FailJson("Failed to get event log: {0}" -f $($_.Exception.Message))
    }

    if($SystemEventLogList.Count -eq 0) {
        $module.FailJson("The event log '$($EventLogName)' doesn't exist")
    }

    if($SystemEventLogList.Count -ne 1) {
        $module.FailJson("Expected to find one Event Log but found '$($SystemEventLogList.Count)'")
    }

    $SystemEventLog = $SystemEventLogList[0]

    if(-not $SystemEventLog.IsEnabled) {
        $SystemEventLog.IsEnabled = $true
        $SystemEventLog.SaveChanges()
        $module.Result.changed = $true
        $module.Result.Msg = "The event log '$($EventLogName)' has been updated"
    }
}

function Disable-SystemEventLog() {
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $EventLogName
    )

    try {
        $SystemEventLogList = [System.Array](Get-WinEvent -ListLog $EventLogName -ErrorAction SilentlyContinue)
    } catch {
        $module.FailJson("Failed to get event log: {0}" -f $($_.Exception.Message))
    }

    if($SystemEventLogList.Count -eq 0) {
        $module.FailJson("The event log '$($EventLogName)' doesn't exist")
    }

    if($SystemEventLogList.Count -ne 1) {
        $module.FailJson("Expected to find one Event Log but found '$($SystemEventLogList.Count)'")
    }

    $SystemEventLog = $SystemEventLogList[0]

    if($SystemEventLog.IsEnabled) {
        $SystemEventLog.IsEnabled = $false
        $SystemEventLog.SaveChanges()
        $module.Result.changed = $true
        $module.Result.Msg = "The event log '$($EventLogName)' has been disabled"
    }
}

if ( -not ($state -eq "disable")) {
	Enable-SystemEventLog -EventLogName $eventLogName
}
else
{
	Disable-SystemEventLog -EventLogName $eventLogName
}

$module.ExitJson()