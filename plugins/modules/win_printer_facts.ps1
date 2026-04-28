#!powershell

# Copyright: (c) 2020-2023, Giesecke Devrient

#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
  supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$module.Result.changed = $false

function Get-InstalledPrinters()
{

  $OutputObjList = New-Object System.Collections.Generic.List[PSObject]

  $Printers = Get-Printer -Full | Select-Object BranchOfficeOfflineLogSizeMB, Caption, Comment, CommunicationStatus, ComputerName,
        Datatype, DefaultJobPriority, Description, DetailedStatus, DisableBranchOfficeLogging,
        DriverName, ElementName, HealthState, InstallDate, InstanceID, JobCount, KeepPrintedJobs,
        Location, Name, OperatingStatus, OperationalStatus, PermissionSDDL, PortName, PrimaryStatus,
        PrintProcessor, Priority, PSComputerName, Published, SeparatorPageFile, Shared, ShareName,
        StartTime, Status, StatusDescriptions, UntilTime, WorkflowPolicy, DeviceType, PrinterStatus, RenderingMode, Type

      foreach ($Printer in $Printers) {
          $properties = @{
                            'Name'=$Printer.Name;
                            'ComputerName'=$Printer.ComputerName;
                            'Type'= [Microsoft.PowerShell.Cmdletization.GeneratedTypes.Printer.TypeEnum].GetEnumName($Printer.Type);
                            'DriverName'=$Printer.DriverName;
                            'PortName'=$Printer.PortName;
                            'Shared'=$Printer.Shared;
                            'ShareName'=$Printer.ShareName;
                            'Published'=$Printer.Published;
                            'Location'=$Printer.Location;
                            'JobCount'=$Printer.JobCount;
                            'KeepPrintedJobs'=$Printer.KeepPrintedJobs;
                            'DeviceType'=[Microsoft.PowerShell.Cmdletization.GeneratedTypes.Printer.DeviceTypeEnum].GetEnumName($Printer.DeviceType);
          }
      $OutputObj = New-Object -TypeName PSObject -Property $properties
      $OutputObjList.Add($OutputObj)
  }
  return $OutputObjList
}

#fetch packages
try
{
  $Printers = Get-InstalledPrinters
}
catch
{
  $module.FailJson("Error fetching installed printers $($_.Exception.Message)")
}

#deal with results
try
{
  if (!$Printers)
  {
    $module.Result.msg = "No printers found"
    $module.Result.exists = $false
  }
  else
  {
    $module.Result.msg = "Printers found"
    $module.Result.exists = $true
    $module.Result.printers = $Printers
  }
}
catch
{
  $module.FailJson("Error dealing with installed printers : $($_.Exception.Message)")
}

$module.ExitJson()
