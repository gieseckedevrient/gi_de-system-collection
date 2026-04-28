#!powershell

# Copyright: (c) 2024, Giesecke Devrient

#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
  options             = @{
    filepattern  = @{ type = "str"; required = $true }
  }
  supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)
$module.Result.changed = $false

$filepattern = $module.Params.filepattern
$checkmode = $module.CheckMode
try
{
  $foundOpenFiles = Get-SmbOpenFile | Where-Object -Property ShareRelativePath -Match $filepattern

  if ($null -ne $foundOpenFiles) {
    $module.Result.sessions = $foundOpenFiles | Select-Object -Property Path,SessionId,ClientComputerName,ClientUserName
    if ( -not $checkmode) {
      $foundOpenFiles | Close-SmbOpenFile -Force
    }
    $module.Result.msg = "${$foundOpenFiles.Count} session(s) closed"
    $module.Result.changed = $true
  }
  else {
    $module.Result.msg = "No found file opened under SMB session matching pattern '$filepattern'"
  }
}
catch
{
  $module.FailJson("Failed to close sessions on files", $_)
}

$module.ExitJson()
