# https://github.com/mkht/DSCR_FileContent

Enum Encoding {
  Default
  utf8
  utf8NoBOM
  utf8BOM
  utf32
  unicode
  bigendianunicode
  ascii
  sjis
}

function Convert-NewLine {
  [OutputType([string])]
  param(
    [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline)]
    [AllowEmptyString()]
    [string]
    $InputObject,

    [Parameter(Position = 1)]
    [ValidateSet('CRLF', 'LF')]
    [string]
    $NewLine = 'CRLF'

  )

  if ($NewLine -eq 'LF') {
    $InputObject.Replace("`r`n", "`n")
  }
  else {
    $InputObject -replace "(?<!\r)\n", "`r`n"
  }
}

function Get-Encoding {
  [OutputType([System.text.Encoding])]
  param(
    [Parameter(Mandatory = $true, Position = 0)]
    [Encoding]
    $Encoding
  )

  switch ($Encoding) {
    'utf8' {
      [System.Text.UTF8Encoding]::new($false) #NoBOM
      break
    }
    'utf8NoBOM' {
      [System.Text.UTF8Encoding]::new($false) #NoBOM
      break
    }
    'utf8BOM' {
      [System.Text.UTF8Encoding]::new($true) #WithBOM
      break
    }
    'utf32' {
      [System.Text.Encoding]::UTF32
      break
    }
    'unicode' {
      [System.Text.Encoding]::Unicode
      break
    }
    'bigendianunicode' {
      [System.Text.Encoding]::BigEndianUnicode
      break
    }
    'ascii' {
      [System.Text.Encoding]::ASCII
      break
    }
    'sjis' {
      [System.Text.Encoding]::GetEncoding(932)
      break
    }
    Default {
      [System.Text.Encoding]::Default
    }
  }
}

function Get-NewContent {
  [CmdletBinding(DefaultParameterSetName = 'Array')]
  [OutputType([string[]], ParameterSetName = 'Array')]
  [OutputType([string], ParameterSetName = 'Raw')]
  param (
    [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [Alias('LiteralPath', 'PSPath')]
    [string[]]$Path,

    [Parameter()]
    [Encoding]$Encoding = 'default',

    [Parameter(ParameterSetName = 'Raw')]
    [switch]$Raw
  )

  Process {
    $NativeEncoding = Get-Encoding $Encoding

    foreach ($item in $Path) {
      try {
        $NativePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($item)
        if ($PSCmdlet.ParameterSetName -eq 'Array') {
          [System.IO.File]::ReadAllLines($NativePath, $NativeEncoding)
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'Raw') {
          [System.IO.File]::ReadAllText($NativePath, $NativeEncoding)
        }
      }
      catch {
        Write-Error -Exception $_.Exception
      }
    }
  }
}

function Set-NewContent {
  param (
    [Parameter(Mandatory, Position = 0)]
    [Alias('LiteralPath', 'PSPath')]
    [string]$Path,

    [Parameter(Mandatory, Position = 1, ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [AllowEmptyString()]
    [string]$Value,

    [Parameter()]
    [Encoding]$Encoding = 'utf8',

    [Parameter()]
    [ValidateSet('CRLF', 'LF')]
    [string]$NewLine = 'CRLF',

    [Parameter()]
    [switch]$NoNewLine,

    [Parameter()]
    [switch]$Force,

    [Parameter()]
    [switch]$PassThru
  )

  Begin {
    $NativeEncoding = Get-Encoding $Encoding

    if ($NoNewLine) {
      $LineFeed = $null
    }
    else {
      $LineFeed = switch -Exact ($NewLine) {
        'CRLF' { $NativeEncoding.GetBytes("`r`n") ; break }
        'LF' { $NativeEncoding.GetBytes("`n") ; break }
        Default { $null }
      }
    }

    $setContentParams = @{
      LiteralPath = $Path
      Force       = $Force
      PassThru    = $PassThru
      NoNewLine   = $NoNewLine
    }

    if ($PSVersionTable.PSVersion.Major -ge 6) {
      $setContentParams.Add('Encoding', $NativeEncoding)
    }
    else {
      if ($Encoding -eq 'utf8BOM') {
        $setContentParams.Add('Encoding', 'utf8')
      }
      else {
        $setContentParams.Add('Encoding', 'Byte')
      }
    }

    $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Set-Content', [System.Management.Automation.CommandTypes]::Cmdlet)
    $scriptCmd = { & $wrappedCmd @setContentParams }
    $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
    $steppablePipeline.Begin($PSCmdlet)
  }

  Process {
    if (($PSVersionTable.PSVersion.Major -ge 6) -or ($Encoding -eq 'utf8BOM')) {
      $steppablePipeline.Process(($Value | Convert-NewLine -NewLine $NewLine))
    }
    else {
      $steppablePipeline.Process(($Value | Convert-NewLine -NewLine $NewLine | ForEach-Object { $NativeEncoding.GetPreamble() + $NativeEncoding.GetBytes($_) + $LineFeed }))
    }
  }

  End {
    $steppablePipeline.End()
  }
}

#region ConvertTo-HashTable
function ConvertTo-HashTable {

  [CmdletBinding()]
  [OutputType([hashtable])]
  param(
    [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
    [AllowNull()]
    [PSObject]
    $InputObject
  )

  if ($InputObject -isnot [System.Management.Automation.PSCustomObject]) {
    return $InputObject
  }

  $Output = [ordered]@{ }
  $InputObject.psobject.properties | Where-Object { $_.MemberType -eq 'NoteProperty' } | ForEach-Object {


    if ($_.Value -is [System.Management.Automation.PSCustomObject]) {
      $Output[$_.Name] = ConvertTo-HashTable -InputObject $_.Value
    }
    elseif ($_.Value -is [Array]) {
      $Output[$_.Name] = @($_.Value | ForEach-Object { ConvertTo-HashTable -InputObject $_ })
    }
    else {
      $Output[$_.Name] = $_.Value
    }
  }

  $Output
}
#endregion ConvertTo-HashTable

#region Compare-Hashtable
function Compare-Hashtable {
  [CmdletBinding()]
  [OutputType([bool])]
  param (
    [Parameter(Mandatory = $true)]
    [Hashtable]$Left,

    [Parameter(Mandatory = $true)]
    [Hashtable]$Right
  )

  $Result = $true

  if ($Left.Keys.Count -ne $Right.keys.Count) {
    $Result = $false
  }

  $Left.Keys | ForEach-Object {

    if (-not $Result) {
      return
    }

    if (-not (Compare-MyObject -Left $Left[$_] -Right $Right[$_])) {
      $Result = $false
    }
  }

  $Result
}
#endregion Compare-Hashtable

#region Compare-MyObject
function Compare-MyObject {
  [CmdletBinding()]
  [OutputType([bool])]
  Param(
    [Parameter(Mandatory = $true)]
    [AllowNull()]
    [Object]$Left,

    [Parameter(Mandatory = $true)]
    [AllowNull()]
    [Object]$Right
  )

  $Result = $true

  if (($null -eq $Left) -or ($null -eq $Right)) {
    $Result = ($null -eq $Left) -and ($null -eq $Right)
  }
  elseif (($Left -as [HashTable]) -and ($Right -as [HashTable])) {
    if (-not (Compare-Hashtable $Left $Right)) {
      $Result = $false
    }
  }
  elseif ($Left.GetType().FullName -ne $Right.GetType().FullName) {
    $Result = $false
  }
  elseif ($Left.Count -ne $Right.Count) {
    $Result = $false
  }
  elseif ($Left.Count -gt 1) {
    $Result = Compare-Array $Left $Right
  }
  else {
    if (Compare-Object $Left $Right -CaseSensitive) {
      $Result = $false
    }
  }

  $Result
}
#endregion Compare-MyObject

#region Compare-Array
function Compare-Array {
  [CmdletBinding()]
  [OutputType([bool])]
  Param(
    [Parameter(Mandatory = $true)]
    [Object[]]$Left,

    [Parameter(Mandatory = $true)]
    [Object[]]$Right
  )

  $Result = $true

  if ($Left.Count -ne $Right.Count) {
    return $false
  }
  else {
    for ($i = 0; $i -lt $Left.Count; $i++) {
      if (-not (Compare-MyObject $Left[$i] $Right[$i])) {
        $Result = $false
        break
      }
    }
  }

  $Result

}
#endregion Compare-Array

#region Format-Json
# Original code obtained from https://github.com/PowerShell/PowerShell/issues/2736
# Formats JSON in a nicer format than the built-in ConvertTo-Json does.
function Format-Json {
  param
  (
    [Parameter(Mandatory, ValueFromPipeline)]
    [String]
    $json
  )

  $indent = 0;
  $result = ($json -Split '\n' |
    ForEach-Object {
      if ($_ -match '[\}\]]') {
        # This line contains  ] or }, decrement the indentation level
        $indent--
      }
      $line = (' ' * $indent * 2) + $_.TrimStart().Replace(':  ', ': ')
      if ($_ -match '[\{\[]') {
        # This line contains [ or {, increment the indentation level
        $indent++
      }
      $line
    }) -Join "`n"

  # Unescape Html characters (<>&')
  $result.Replace('\u0027', "'").Replace('\u003c', "<").Replace('\u003e', ">").Replace('\u0026', "&")

}
#endregion Format-Json

$export_members = @{
  Function = "Convert-NewLine", "Get-Encoding", "Get-NewContent", "Set-NewContent", "ConvertTo-HashTable", "Compare-Hashtable", "Compare-MyObject", "Compare-Array", "Format-Json"
  Variable = "Encoding"
}
Export-ModuleMember @export_members
