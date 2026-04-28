#!powershell

#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
    options = @{
        number = @{ type='int'; required=$true }
        partition_style_set = @{ type='str'; default='gpt'; choices = @("gpt", "mbr") }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$Number = $module.Params.number
$SetPartitionStyle = $module.Params.partition_style_set

$module.result.changed = $false

if ([int32]2147483647 -lt $Number) {
    $module.failJson("Number option must be of type int32")
}

# Functions
function Set-OperationalStatus {
        param(
                $Disk,
                [switch]$Deactivate
        )
        $null = Set-Disk -Number ($Disk.Number) -IsOffline $Deactivate.IsPresent
}

function Set-DiskWriteable {
        param(
                $Disk,
                [switch]$Deactivate
        )
        $null = Set-Disk -Number ($Disk.Number) -IsReadonly $Deactivate.IsPresent
}

function Set-Initialized {
        param(
                $Disk,
                $PartitionStyle
        )
        $null = $Disk| Initialize-Disk -PartitionStyle $PartitionStyle -Confirm:$false
}

# Search disk
try {
    $disk = Get-Disk | Where-Object { $_.Number -eq $Number }
} catch {
    $module.failJson("Failed to search and/or select the disk with the specified option values: {0}" -f $($_.Exception.Message))
}
if ($disk) {
    [string]$DOperSt = $disk.OperationalStatus
    [string]$DPartStyle = $disk.PartitionStyle
    [string]$DROState = $disk.IsReadOnly
} else {
    $module.failJson("No disk could be found and selected with the passed option values")
}

# Check and set operational status and read-only state
$SetOnline = $false
$SetWriteable = $false
$OPStatusFailed = $false
$ROStatusFailed = $false
if ($DPartStyle -ne "RAW") {
    if ($DOperSt -ne "Online") {
        if (-not $check_mode) {
            # Set online
            try {
                Set-OperationalStatus -Disk $disk
            } catch {
                $module.failJson("Failed to set the disk online: {0}" -f $($_.Exception.Message))
            }
            $module.result.changed = $true
            $SetOnline = $true
        }
    }
    if ($DROState -eq "True") {
        if (-not $check_mode) {
            # Set writeable
            try {
                Set-DiskWriteable -Disk $disk
            } catch {
                if ($SetOnline) {
                    try {
                        Set-OperationalStatus -Disk $disk -Deactivate
                    } catch {
                        $OPStatusFailed = $true
                    } finally {
                        if (-not $OPStatusFailed) {
                            $module.result.changed = $true
                        }
                    }
                }
                $module.failJson("Failed to set the disk from read-only to writeable state: {0}" -f $($_.Exception.Message))
            }
            $module.result.changed = $true
            $SetWriteable = $true
        }
    }
}

# Initialize / convert disk
if ($DPartStyle -eq "RAW") {
    if (-not $check_mode) {
        if ($DOperSt -eq "Offline") {
            $SetOnline = $true
        }
        if ($DROState -eq "True") {
            $SetWriteable = $true
        }
        # Initialize disk
        try {
            Set-Initialized -Disk $disk -PartitionStyle $SetPartitionStyle
        } catch {
            $GetDiskFailed = $false
            $FailDisk = $null
            if ($SetOnline) {
                try {
                    $FailDisk = Get-Disk -Number $disk.Number
                } catch {
                    $GetDiskFailed = $true
                } finally {
                    if (-not $GetDiskFailed) {
                        try {
                            Set-OperationalStatus -Disk $disk -Deactivate
                        } catch {
                            $OPStatusFailed = $true
                        }
                        if (-not $OPStatusFailed) {
                            $module.result.changed = $true
                        }
                    }
                }
            }
            if ($SetWriteable) {
                if (-not $FailDisk) {
                    try {
                        $FailDisk = Get-Disk -Number $disk.Number
                    } catch {
                        $GetDiskFailed = $true
                    }
                }
                if (-not $GetDiskFailed) {
                    try {
                        Set-DiskWriteable -Disk $disk -Deactivate
                    } catch {
                        $ROStatusFailed = $true
                    } finally {
                        if (-not $ROStatusFailed) {
                            $module.result.changed = $true
                        }
                    }
                }
            }
            $module.failJson("Failed to initialize the disk: {0}" -f $($_.Exception.Message))
        }
        $module.result.changed = $true
    }
}

# Return result
$module.ExitJson()
