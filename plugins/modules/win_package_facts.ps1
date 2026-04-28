#!powershell

# Copyright: (c) 2020-2023, Giesecke Devrient

#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
  options             = @{
    name    = @{ type = "str" }
    appGUID = @{ type = "str" }
  }
  mutually_exclusive  = @(, @('name', 'appGUID'))
  required_one_of     = @(, @('name', 'appGUID'))
  supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)
$name = $module.Params.name
$appGUID = $module.Params.appGUID

$module.Result.changed = $false
$module.Result.exists = $false

function Get-InstalledSoftware()
{
  $UninstallRegKeys = @("HKLM:/SOFTWARE/Microsoft/Windows/CurrentVersion/Uninstall",
    "HKLM:/SOFTWARE/Wow6432Node/Microsoft/Windows/CurrentVersion/Uninstall")
  $OutputObjList = { New-Object -TypeName PSobject }.Invoke()
  foreach ($UninstallRegKey in $UninstallRegKeys)
  {
    try
    {
      $UninstallRef += Get-ChildItem -Path $UninstallRegKey | Get-ItemProperty
    }
    catch
    {
      # to adjust
      Continue
    }
    $OutputObjList = { New-Object -TypeName PSobject }.Invoke()

    foreach ($App in $UninstallRef)
    {
      $AppGUID = $App.PSChildName
      $AppDisplayName = $App.DisplayName
      $AppVersion = $App.DisplayVersion
      $AppPublisher = $App.Publisher
      $AppInstalledDate = $App.InstallDate
      $AppUninstall = $App.UninstallString
      if ($App.PSPath -match "Wow6432Node")
      {
        $Softwarearchitecture = "x86"
      }
      else
      {
        $Softwarearchitecture = "x64"
      }
      if (!$AppDisplayName) { continue }
      $OutputObj = New-Object -TypeName PSobject
      $OutputObj | Add-Member -MemberType NoteProperty -Name AppName -Value $AppDisplayName
      $OutputObj | Add-Member -MemberType NoteProperty -Name AppVersion -Value $AppVersion
      $OutputObj | Add-Member -MemberType NoteProperty -Name AppVendor -Value $AppPublisher
      $OutputObj | Add-Member -MemberType NoteProperty -Name InstalledDate -Value $AppInstalledDate
      $OutputObj | Add-Member -MemberType NoteProperty -Name UninstallKey -Value $AppUninstall
      $OutputObj | Add-Member -MemberType NoteProperty -Name AppGUID -Value $AppGUID
      $OutputObj | Add-Member -MemberType NoteProperty -Name SoftwareArchitecture -Value $Softwarearchitecture
      $OutputObjList.Add($OutputObj)
    }
  }
  return $OutputObjList
}

#fetch packages
try
{
  if (!$name -and !$appGUID )
  {
    $module.FailJson("both name and appGUID are empty, one of the three is mandatory")
  }
  if ($name)
  {
    $Packages = Get-InstalledSoftware | Where-Object { $_.AppName -match $name }
  }
  else
  {
    $Packages = Get-InstalledSoftware | Where-Object { $_.AppGUID -eq $appGUID }
  }
}
catch
{
  $module.FailJson("Error fetching installed packages $($_.Exception.Message)")
}

#deal with results
try
{
  if (!$Packages)
  {
    $module.Result.msg = "Software not found"
    $module.Result.exists = $false
    $module.Result.Packages = $null
  }
  else
  {
    $module.Result.msg = "Software found"
    $module.Result.exists = $true
    $module.Result.Packages = $Packages
  }
}
catch
{
  $module.FailJson("Error dealing with installed packages : $($_.Exception.Message)")
}

$module.ExitJson()
