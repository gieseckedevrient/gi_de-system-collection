#!powershell

# Copyright: (c) 2025, Giesecke Devrient

#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
  options = @{
    provider = @{ type = "str" ; default = "" }
    class_name = @{ type = "str" ; default = "Printer" }
  }
  supports_check_mode = $false
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)
$module.Result.changed = $false

$provider = $module.Params.provider
$className = $module.Params.class_name

try {
  $drivers = (Get-WindowsDriver -online | Where-Object { $_.ClassName -eq $className -and $_.ProviderName -match $provider})
}
catch {
  $module.FailJson("Failed Getting drivers. using params $($params)", $_)
}

try {
  $module.Result.drivers = @() # empty result

  if ($drivers.Count -gt 0) {
    $module.Result.msg += "$($drivers.Count) divers(s) found"
    foreach ($driver in $drivers) {
      $driver_info = @{}
      $driver_info.Driver = $driver.Driver
      $driver_info.OriginalFileName = $driver.OriginalFileName
      $driver_info.ClassName = $driver.ClassName.ToString()
      $driver_info.ProviderName = $driver.ProviderName
      $driver_info.Date = $driver.Date.ToString()
      $driver_info.Version = $driver.Version
      $module.Result.drivers += $driver_info
    }
  }
  else {
    $module.Result.msg += "No drivers found"
  }
}
catch {
  $module.FailJson("Failed Parsing found drivers", $_)
}

$module.ExitJson()
