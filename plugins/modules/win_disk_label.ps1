#!powershell

# Copyright: (c) 2025,  Giesecke Devrient

#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
  options = @{
    driveLetter = @{ type = "str"; required = $true }
    label = @{ type = "str"; required = $true }
  }
  supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)
$module.Result.changed = $false

$driveLetter = $module.Params.driveLetter
$label = $module.Params.label

function Get-VolumeFromLetter {
    param(
        [Parameter(Mandatory = $true)]
        [String]$driveLetter
    )
  # fetch from https://github.com/ansible-collections/community.windows/blob/main/plugins/modules/win_format.ps1#L82
  $partition = Get-Partition -DriveLetter $DriveLetter | Where-Object { $null -ne $_.DiskNumber }
  $volume = Get-Volume -Partition $partition
  return $volume
}

$currentVolume = Get-VolumeFromLetter -driveLetter $driveLetter
$module.Result.changed = $false

if($null -eq $currentVolume) {
  $module.FailJson("No volume found with letter $($driveLetter)")
}

if(-not ($currentVolume.FileSystemLabel -eq $label)){

  if (-not $module.CheckMode){
    try {
      $currentVolume | Set-Volume -NewFileSystemLabel $label
      $module.Result.changed = $true
      $module.Result.msg = "Volume label changed from $($currentVolume.FileSystemLabel) to $($label)"
    } catch {
      $module.FailJson("Error on renaming volume: $($_.Exception.Message)")
    }
  }
  else {
    # don't do
    $module.Result.changed = $true
    $module.Result.msg = "Volume label would change from $($currentVolume.FileSystemLabel) to $($label)"
  }
} else {
  $module.Result.msg = 'Volume has the already the right label'
}

$module.ExitJson()
