#!powershell

# Copyright: (c) 2019, Giesecke Devrient

#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
  options = @{
    name = @{ type = "str"; required = $true }
    port = @{ type = "str"; required = $true }
    driver = @{ type = "str"; required = $true }
    state = @{ type = "str"; choices = "absent", "present"; default = "present" }
  }
  supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)
$module.Result.changed = $false

$name = $module.Params.name
$port = $module.Params.port
$driver = $module.Params.driver
$state = $module.Params.state

function Test-PortPresent()
{
  $PrinterPortObj = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Ports" -Name $port -ErrorAction Ignore
  if($PrinterPortObj){
    return $true
   } else {
    return $false
   }
}

function Test-DriverPresent()
{
  $PrinterDriverObj = Get-WmiObject -Class "Win32_PrinterDriver" -Filter "Name like '$driver,%'"
  if($PrinterDriverObj){
    return $true
   } else {
    return $false
   }
}

function Test-PrinterPresent()
{
  $PrinterObj = Get-WmiObject -Class "Win32_Printer" -Filter "Name like '$name'"
  if($PrinterObj){
    return $true
   } else {
    return $false
   }
}

function Test-PrinterUpToDate()
{
  $PrinterObj = Get-WmiObject -Class "Win32_Printer" -Filter "Name like '$name'"
  if($PrinterObj.DriverName -ne $driver) {
    return $false
  }
  if($PrinterObj.PortName -ne $port) {
    return $false
  }
  return $true
}

function Remove-Printer()
{
  $PrinterObj = Get-WmiObject -Class "Win32_Printer" -Filter "Name like '$name'"
  try {
    $PrinterObj.Delete() | Out-Null
  }
  catch {
    $module.FailJson("Error on removing Printer: $($_.Exception.Message)")
  }
}

function Add-Printer()
{
  If (-not (Test-PortPresent)) {
    $module.FailJson("Error on installing Printer: Port is missing!")
  }
  If (-not (Test-DriverPresent)) {
    $module.FailJson("Error on installing Printer: Driver is missing!")
  }

  try {
    $PrinterClass = [WMIClass]"Win32_Printer"
    $PrinterClass.Scope.Options.EnablePrivileges = $true
    $PrinterObj = $PrinterClass.CreateInstance()
    $PrinterObj.DeviceID = $name
    $PrinterObj.DriverName = $driver
    $PrinterObj.PortName = $port
    $PrinterObj.Put() | Out-Null
  }
  catch {
    $module.FailJson("Error on installing Printer: $($_.Exception.Message)")
  }
}

function Update-Printer()
{
  If (-not (Test-PortPresent) -or -not (Test-DriverPresent)) {
    $module.FailJson("Error on updating Printer: Driver or Port is missing!")
  }

  $PrinterObj = Get-WmiObject -Class "Win32_Printer" -Filter "Name like '$name'"

  try {
    $PrinterObj.DriverName = $driver
    $PrinterObj.PortName = $port
    $PrinterObj.Put() | Out-Null
  }
  catch {
    $module.FailJson("Error on updating Printer: $($_.Exception.Message)")
  }
}

if (-not ($state -eq "absent")) {
  if (Test-PrinterPresent) {
    if(-not (Test-PrinterUpToDate)) {
      if(-not ($module.CheckMode)) {
        Update-Printer
      }
      $module.Result.changed = $true
    }
  } else {
    Add-Printer
    $module.Result.changed = $true
  }
} else {
  if (Test-PrinterPresent) {
    if(-not ($module.CheckMode)) {
      Remove-Printer
    }
    $module.Result.changed = $true
  }
}

$module.ExitJson()
