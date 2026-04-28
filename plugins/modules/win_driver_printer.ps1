#!powershell

# Copyright: (c) 2019, Giesecke Devrient
# courtesy to https://github.com/daBONDi/ansible-role-win-printer-driver/blob/master/library/win_printer_driver.ps1

#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
  options = @{
    inf_path = @{ type = "str"; required = $true }
    driver_name = @{ type = "str"; required = $true }
    printer_env = @{ type = "str"; choices = "x86", "x64"; default = "x64" }
    state = @{ type = "str"; choices = "absent", "present"; default = "present" }
  }
  supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)
$module.Result.changed = $false

$inf_path = $module.Params.inf_path
$driver_name = $module.Params.driver_name
$printer_env = $module.Params.printer_env
$state = $module.Params.state

switch ($printer_env) {
  x64 { $printer_environment = "Windows x64" }
  x86 { $printer_environment = "Windows NT x86" }
}
function Test-DriverPresent()
{
  $PrinterDriverObj = Get-WmiObject -Class "Win32_PrinterDriver" -Filter "SupportedPlatform = '$printer_environment' and Name like '$driver_name,%'"
  if($PrinterDriverObj){
    return $true
   } else {
    return $false
   }
}

function Install-Driver()
{
  if(-not (Test-Path -Path $inf_path)){
    $module.FailJson("Cannot find or access the Driver INF path : $($_.Exception.Message)")
  }

  try {
    $PrinterDriverClass = [WMIClass]"Win32_PrinterDriver"
		$PrinterDriverClass.Scope.Options.EnablePrivileges = $true
		$PrinterDriverObj = $PrinterDriverClass.CreateInstance()
		$PrinterDriverObj.Name = $driver_name
		$PrinterDriverObj.DriverPath =  $inf_path
    $PrinterDriverObj.SupportedPlatform = $printer_environment
    $PrinterDriverObj.Version = 3
		$ReturnValue = $PrinterDriverClass.AddPrinterDriver($PrinterDriverObj)
		$Null = $PrinterDriverClass.Put()
		if ( $ReturnValue.ReturnValue -ne 0 ) {
      $module.FailJson("Error on installing Printer Driver: $($ReturnValue.ReturnValue)")
		}
  }
  catch {
    $module.FailJson("Error on installing Printer Driver: $($_.Exception.Message)")
  }
}

function Uninstall-Driver()
{

  try {
    Remove-PrinterDriver -Name "$driver_name"
    # below command do not raise any error, so using alternate above
    # eg. if the driver is in use.
    # RUNDLL32 PRINTUI.DLL,PrintUIEntry /dd /m $driver_name /h $printer_env /v $os_driver_support_version
    # https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/rundll32-printui
    #
    ##AnsibleRequires -PowerShell ansible_collections.ansible.windows.plugins.module_utils.Process
    # $PrinterDriverObj = Get-WmiObject -Class "Win32_PrinterDriver" -Filter "SupportedPlatform = '$printer_environment' and Name like '$driver_name,%'"
    # $os_driver_support_version = $PrinterDriverObj.Version
    # $res = Start-AnsibleWindowsProcess `
    #     -FilePath "rundll32.exe" `
    #     -ArgumentList @('PRINTUI.DLL,PrintUIEntry',
    #         '/dd', # Deletes a printer driver.
    #         '/m', $driver_name, # Specifies the driver model name
    #         '/h', $printer_env, # Specifies the driver architecture.
    #         '/v', $os_driver_support_version
    #         # )
    #         '/q') # Runs the command with no notifications to the user.
    # $module.Result.cmdline = $res.Command
    # $module.Result.stdout = $res.Stdout
    # $module.Result.rc = $res.ExitCode
    # if ($res.ExitCode -ne 0) {
    #     $module.Result.stderr = $res.Stderr
    #     $module.Result.rc = $res.ExitCode
    #     $module.FailJson("Failed to remove driver, see stdout/stderr for more details", $($res.Stderr))
    # }
  }
  catch {
    $module.FailJson("Error on uninstalling Printer Driver: $($_.Exception.Message)")
  }
}

$driver_present = Test-DriverPresent

if($state -ne "absent") {
  # Ensure driver is installed
  if (-not $driver_present) {
    if (-not $module.CheckMode) {
      Install-Driver
    }
    $module.Result.changed = $true
  }
} else {
  # Ensure driver is uninstalled
  if ($driver_present) {
    if (-not $module.CheckMode) {
      Uninstall-Driver
    }
    $module.Result.changed = $true
  }
}

$module.ExitJson()
