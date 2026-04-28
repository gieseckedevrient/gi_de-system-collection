#!powershell

# Copyright: (c) 2021, Giesecke Devrient
# https://github.com/mkht/DSCR_FileContent

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.gi_de.system.plugins.module_utils.Json

$spec = @{
  options             = @{
    state    = @{ type = "str"; default = "present"; choices = "present", "absent" }
    path     = @{ type = "str"; required = $true }
    settings = @{ type = "dict"; required = $true }
    mode     = @{ type = "str"; default = "Value"; choices = "Value", "ArrayElement" }
    encoding = @{ type = "str"; default = "utf8NoBOM"; choices = "utf8", "utf8NoBOM", "utf8BOM", "utf32", "unicode", "bigendianunicode", "ascii", "sjis", "Default" }
    newline  = @{ type = "str"; default = "CRLF"; choices = "CRLF", "LF" }
  }
  supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$State = $module.Params.state
$Path = $module.Params.path
$Settings = $module.Params.settings
$Mode = $module.Params.mode
$Encoding = $module.Params.encoding
$Newline = $module.Params.newline

## Try to load current settings
$JsonHash = $null
if (Test-Path -Path $Path -PathType Leaf) {
  $JsonHash = try {
    $Json = Get-NewContent -Path $Path -Raw -Encoding $Encoding | ConvertFrom-Json -ErrorAction Ignore
    if ($Json) {
      ConvertTo-HashTable -InputObject $Json
    }
  }
  catch { }
}

$SettingsUpdated = @()
$SettingsDeleted = @()

## Loop on the settings provided
foreach ($Setting in $Settings.GetEnumerator()) {

  # State = "absent"
  if ($State -eq 'absent') {
    if ($JsonHash) {
      $KeyHierarchy = $Setting.Key -split '(?<!\\)/' -replace '\\/', '/'
      $expression = '$JsonHash'
      for ($i = 0; $i -lt $KeyHierarchy.Count; $i++) {
        if ($i -ne ($KeyHierarchy.Count - 1)) {
          $expression += (".'{0}'" -f $KeyHierarchy[$i])
        }
        else {
          if (Invoke-Expression -Command $expression) {
            switch ($Mode) {
              'Value' {
                $module.Debug('The key "{0}" will be removed' -f $KeyHierarchy[$i])
                $expression += (".Remove('{0}')" -f $KeyHierarchy[$i])
                $SettingsDeleted += $Setting.Key
              }
              'ArrayElement' {
                $tmpex = $expression + (".'{0}'" -f $KeyHierarchy[$i])
                $v = Invoke-Expression -Command $tmpex
                if ($v -is [Array]) {
                  $script:newValue = $v | Where-Object { -not (Compare-MyObject $_ $ValueObject) }
                  if ($null -eq $script:newValue) {
                    $module.Debug('The key "{0}" will be removed' -f $KeyHierarchy[$i])
                    $expression += (".Remove('{0}')" -f $KeyHierarchy[$i])
                    $SettingsDeleted += $Setting.Key
                  }
                  else {
                    $module.Debug('The key "{0}" will be modified' -f $KeyHierarchy[$i])
                    $expression += ('."{0}" = @($script:newValue)' -f $KeyHierarchy[$i])
                    $SettingsUpdated += $Setting.Key
                  }
                }
                else {
                  $module.Debug('The key "{0}" will be removed' -f $KeyHierarchy[$i])
                  $expression += (".Remove('{0}')" -f $KeyHierarchy[$i])
                  $SettingsDeleted += $Setting.Key
                }
              }
            }
          }
        }
      }
      Invoke-Expression -Command $expression
    }
  }
  else {

    # State = "present"
    if ($null -eq $JsonHash) {
      $JsonHash = @{ }
    }

    ## Type provided value
    $ValueObject = $null
    $tmp = try {
      ConvertFrom-Json -InputObject $Setting.Value -ErrorAction Ignore
    }
    catch { }
    if ($null -eq $tmp) {
      if ([bool]::TryParse($Setting.Value, [ref]$null)) {
        $ValueObject = [bool]::Parse($Setting.Value)
      }
      elseif ($Value -eq 'null') {
        $ValueObject = $null
      }
      else {
        $ValueObject = $Setting.Value
      }
    }
    elseif ($tmp.GetType().Name -eq 'PSCustomObject') {
      $ValueObject = ConvertTo-HashTable -InputObject $tmp
    }
    else {
      $ValueObject = $tmp
    }
    # Workaround for ConvertTo-Json bug
    # https://github.com/PowerShell/PowerShell/issues/3153
    if ($ValueObject -is [Array]) {
      $ValueObject = $ValueObject.SyncRoot
    }

    $KeyHierarchy = $Setting.Key -split '(?<!\\)/' -replace '\\/', '/'
    $tHash = $JsonHash
    for ($i = 0; $i -lt $KeyHierarchy.Count; $i++) {
      if ($i -lt ($KeyHierarchy.Count - 1)) {
        if (-not $tHash.Contains($KeyHierarchy[$i])) {
          $tHash.($KeyHierarchy[$i]) = @{ }
        }
        elseif (-not ($tHash.($KeyHierarchy[$i]) -as [hashtable])) {
          $tHash.($KeyHierarchy[$i]) = @{ }
        }
        $tHash = $tHash.($KeyHierarchy[$i])
      }
      else {
        switch ($Mode) {
          'Value' {
            if (-not (Compare-MyObject $tHash.($KeyHierarchy[$i]) $ValueObject)) {
              $module.Debug('The key "{0}" will be modified' -f $KeyHierarchy[$i])
              $tHash.($KeyHierarchy[$i]) = $ValueObject
              $SettingsUpdated += $Setting.Key
            }
          }
          'ArrayElement' {
            if ($tHash.($KeyHierarchy[$i]) -is [Array]) {
              if ($tHash.($KeyHierarchy[$i]) | Where-Object { -not (Compare-MyObject $_ $ValueObject) }) {
                $module.Debug('The key "{0}" will be modified' -f $KeyHierarchy[$i])
                $tHash.($KeyHierarchy[$i]) += $ValueObject
                $SettingsUpdated += $Setting.Key
              }
            }
            elseif ($tHash.Contains($KeyHierarchy[$i])) {
              $newValue = @($tHash.($KeyHierarchy[$i]), $ValueObject)
              $module.Debug('The key "{0}" will be modified' -f $KeyHierarchy[$i])
              $tHash.($KeyHierarchy[$i]) = $newValue
              $SettingsUpdated += $Setting.Key
            }
            else {
              $module.Debug('The key "{0}" will be modified' -f $KeyHierarchy[$i])
              $tHash.($KeyHierarchy[$i]) = @($ValueObject)
              $SettingsUpdated += $Setting.Key
            }
          }
        }
        break
      }
    }
  }
}

if (($SettingsUpdated.Length -eq 0) -and ($SettingsDeleted.Length -eq 0)) {
  $module.Result.changed = $false
  $module.Result.msg = "All settings are up-to-date."
}
else {
  if (-not $module.CheckMode) {
    # Create directory if not exist
    $ParentFolder = Split-Path -Path $Path -Parent -ErrorAction SilentlyContinue
    if ($ParentFolder -and (-not (Test-Path -Path $ParentFolder -PathType Container))) {
      $null = New-Item -Path $ParentFolder -ItemType Directory -Force -ErrorAction Stop
    }

    # Save Json file
    ConvertTo-Json -InputObject $JsonHash -Depth 100 | Format-Json | Out-String | Set-NewContent -Path $Path -Encoding $Encoding -NewLine $NewLine -NoNewline -Force -ErrorAction Stop
    $module.Debug('Json file "{0}" has been saved' -f $Path)
  }
  $module.Result.changed = $true
  $module.Result.msg = "" + $SettingsUpdated.Length + " settings updated, " + $SettingsDeleted.Length + " settings deleted"
  $module.Result.settingsupdated = $SettingsUpdated
  $module.Result.settingsdeleted = $SettingsDeleted
}

$module.ExitJson()
