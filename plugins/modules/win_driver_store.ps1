#!powershell

# Copyright: (c) 2019, Giesecke Devrient

#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
  options             = @{
    url      = @{ type = "str" }
    inf_path = @{ type = "str"; }
    is_local = @{ type = "bool"; default = "false" }
    name     = @{ type = "str"; required = $true }
    state    = @{ type = "str"; choices = "absent", "present"; default = "present" }
  }
  supports_check_mode = $true
  mutually_exclusive  = @(
    , @('url', 'inf_path')
  )
  required_if         = @(
    , @('is_local', $false, @('url'))
    , @('is_local', $true, @('inf_path'))
  )
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)
$module.Result.changed = $false

$url = $module.Params.url
$name = $module.Params.name
$state = $module.Params.state
$isLocal = $module.Params.is_local
$infPath = $module.Params.inf_path

function New-TemporaryDirectory {
  $parent = [System.IO.Path]::GetTempPath()
  [string] $name = [System.Guid]::NewGuid()
  $directory = New-Item -ItemType Directory -Path (Join-Path $parent $name)
  return $directory
}

function Test-DriverPresent() {
  if (!$isLocal) {
    $Files = Get-ChildItem C:\Windows\INF\*.inf
    $driver = Select-String -Pattern $name -Path $Files
  }
  else {
    $File = Get-Item -Path ($infPath)
    $driver = (Get-WindowsDriver -online | Where-Object OriginalFileName -Match $File.Name)
  }
  if ($driver.Count) {
    return $true
  }
  else {
    return $false
  }
}

function Install-Driver() {
  try {
    if (!$isLocal) {
      # Download & expand cab
      $TempFile = New-TemporaryFile
      $TempDir = New-TemporaryDirectory
      Invoke-WebRequest -Uri $url -OutFile $TempFile
      Expand-Archive -Path $TempFile -OutputPath $TempDir.FullName
      $File = Get-Item -Path ($TempDir.FullName + "\*.inf")
    }
    else {
      $File = Get-Item -Path ($infPath)
    }
    $module.Result.pnputilOutput = &"pnputil.exe" -i -a $($File.FullName) 2>&1
    # -i : install    == /install
    # -a : add driver == /add-driver
  }
  catch {
    $module.FailJson("Error on installing Driver: $($_.Exception.Message)")
  }
  finally {
    if (!$isLocal) {
      Remove-Item -Path $TempFile -Force
      Remove-Item -Path $TempDir -Recurse -Force
    }
  }
}

function Uninstall-Driver() {
  # DO NOT Work with CAB file...
  if (!$isLocal) {
    $File = Get-Item -Path (Select-String -Pattern "Generic / Text Only" -Path $Files).Path
  }
  else {
    $File = Get-Item -Path ($infPath)
  }
  # Find the oemxx.inf originating from provided
  $File = Get-Item -Path ($infPath)
  $driver = (Get-WindowsDriver -online | Where-Object OriginalFileName -Match $File.Name).Driver

  try {
    $module.Result.pnputilOutput = &"pnputil.exe" -f -d $($driver) 2>&1
    # -f : force == /force
    # -d  : delete == /delete-driver
  }
  catch {
    $module.FailJson("Error on uninstalling Driver: $($_.Exception.Message)")
  }
}

$driver_present = Test-DriverPresent

if ($state -ne "absent") {
  # Ensure driver is stored
  if (-not $driver_present) {
    if (-not $module.CheckMode) {
      Install-Driver
    }
    $module.Result.changed = $true
  }
}
else {
  # Ensure driver is removed
  if ($driver_present) {
    if (-not $module.CheckMode) {
      Uninstall-Driver
    }
    $module.Result.changed = $true
  }
}

$module.ExitJson()
