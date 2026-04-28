#!powershell

#AnsibleRequires -CSharpUtil Ansible.Basic

# This modules does not accept any options
$spec = @{
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

# First try to find the product key from ACPI
$volume = Get-Volume | Where-Object { $_.DriveType -eq "CD-ROM" }

if ($volume) {
    $module.Result.ansible_facts = @{
        cdrom_driveletter = $volume.DriveLetter
        cdrom_drivetype = $volume.DriveType
        cdrom_operationalstatus = $volume.OperationalStatus
        cdrom_healthstatus = $volume.HealthStatus
        cdrom_filesystem = $volume.FileSystem
        cdrom_filesystemlabel = $volume.FileSystemLabel
        cdrom_size = $volume.Size
    }
}

$module.ExitJson()
