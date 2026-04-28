#!powershell

# Copyright: (c) 2020, Giesecke Devrient

#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
  options = @{
      category = @{ type = "str"; required = $true }
      categorytype =  @{ type = "str"; choices = "SingleInstance", "MultiInstance"; default = "SingleInstance" }
      categorydescription = @{ type = "str"; required = $false ; default = ""}
      counters = @{
        type = "list"
        elements = "dict"
        options = @{
          CounterName = @{ type = "str"; required = $true }
          CounterType = @{ type = "str"; default = "" ; choices = "NumberOfItemsHEX32" , "NumberOfItemsHEX64" , "NumberOfItems32" , "NumberOfItems64" , "CounterDelta32" , "CounterDelta64" , "SampleCounter" , "CountPerTimeInterval32" , "CountPerTimeInterval64" , "RateOfCountsPerSecond32" , "RateOfCountsPerSecond64" , "RawFraction" , "CounterTimer" , "Timer100Ns" , "SampleFraction" , "CounterTimerInverse" , "Timer100NsInverse" , "CounterMultiTimer" , "CounterMultiTimer100Ns" , "CounterMultiTimerInverse" , "CounterMultiTimer100NsInverse" , "AverageTimer32" , "ElapsedTime" , "AverageCount64" , "SampleBase" , "AverageBase" , "RawBase" , "CounterMultiBase"}
          CounterDescription = @{ type = "str" }
        }
      }
      state = @{ type = "str"; choices = "absent", "present"; default = "present" }
  }
  required_if = @(,@("state", "present", @("category","counters")))
  supports_check_mode = $false
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$category = $module.Params.category
$counterCollection = $module.Params.counters
$state = $module.Params.state
$categorytype = $module.Params.categorytype
$categorydescription = $module.Params.categorydescription

function Test-PerfCounterCategory
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the cateogry whose existence to check.
        $CategoryName,

        [Parameter(Mandatory=$false)]
        [Diagnostics.PerformanceCounterCategoryType]
        # The performance counter's category type.
        $CategoryType,

        [Parameter(Mandatory=$false)]
        [string]
        # The performance counter's category type.
        $CategoryDescription
    )
    $exists = [Diagnostics.PerformanceCounterCategory]::Exists( $CategoryName )
    if ($exists -and !$CategoryType -and $CategoryDescription -ne '' )
    {
      $existingCategory = New-Object Diagnostics.PerformanceCounterCategory $CategoryName
      $sameType = ( $existingCategory.CategoryType -eq $CategoryType)
      if (!$sameType)
      {
        $module.Warn("$($CategoryName) did not match Type")
      }
      $sameDescription = ( $existingCategory.CategoryHelp -eq $CategoryDescription)
      if (!$sameDescription)
      {
        $module.Warn("$($CategoryName) did not match Description")
      }
      $exists = ( $exists -and $sameType -and $sameDescription )
    }
    return $exists
}
function Get-PerfCounter
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The category's name whose performance counters will be returned.
        $CategoryName
    )

    if( (Test-PerfCounterCategory -CategoryName $CategoryName) )
    {
        $category = New-Object Diagnostics.PerformanceCounterCategory $CategoryName
        return $category.GetCounters("")
    }
}



function Test-PerfCounter
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The category's name where the performance counter exists.  Or might exist.  As the case may be.
        $CategoryName,

        [Parameter(Mandatory=$true)]
        [string]
        # The performance counter's name.
        $Name,

        [Parameter(Mandatory=$true)]
        [Diagnostics.PerformanceCounterType]
        # The performance counter's type (from the Diagnostics.PerformanceCounterType enumeration).
        $Type,

        [Parameter(Mandatory=$false)]
        [string]
        # The performance counter's description (i.e. help message).
        $Description
    )
      try {
        Set-StrictMode -Version 'Latest'

        if( (Test-PerfCounterCategory -CategoryName $CategoryName) )
        {
          $exists = [Diagnostics.PerformanceCounterCategory]::CounterExists( $Name, $CategoryName )
          if ($exists )
          {
            $existingCounter = New-Object System.Diagnostics.PerformanceCounter $CategoryName, $Name, $true
            $sameType = ( $existingCounter.CounterType -eq $Type)
            if ($exists -and !$Description )
            {
              $sameDescription = ( $existingCounter.CounterHelp -eq $Description)
              $exists = ( $exists -and $sameDescription )
            }
            $exists = ( $exists -and $sameType )
          return $exists
        }

        return $false
        }
      }
        catch {
          $module.Fail("Failed checking the existing counter: $($Name)")
        }

}

function Uninstall-PerfCounterCategory
{
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The performance counter's category name that should be deleted.
        $CategoryName
    )

    Set-StrictMode -Version 'Latest'

    if( (Test-PerfCounterCategory -CategoryName $CategoryName) )
    {

            [Diagnostics.PerformanceCounterCategory]::Delete( $CategoryName )
            $module.Debug("$($CategoryName) deleted")

    }
}


function Install-PerfCounter
{
    [CmdletBinding(DefaultParameterSetName='SimpleCounter')]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The category's name where the counter will be created.
        $CategoryName,

        [Parameter(Mandatory=$true)]
        [Diagnostics.PerformanceCounterCategoryType]
        # The performance counter's category type.
        $CategoryType,

        [Parameter(Mandatory=$true)]
        [string]
        # The performance counter's category type.
        $CategoryDescription,

        [Parameter(Mandatory=$true)]
        [string]
        # The performance counter's name.
        $Name,

        [Parameter(Mandatory=$true)]
        [string]
        # The performance counter's description (i.e. help message).
        $Description,

        [Parameter(Mandatory=$true)]
        [Diagnostics.PerformanceCounterType]
        # The performance counter's type (from the Diagnostics.PerformanceCounterType enumeration).
        $Type,

        [Parameter(Mandatory=$true,ParameterSetName='WithBaseCounter')]
        [string]
        # The base performance counter's name.
        $BaseName,

        [Parameter(ParameterSetName='WithBaseCounter')]
        [string]
        # The base performance counter's description (i.e. help message).
        $BaseDescription,

        [Parameter(Mandatory=$true,ParameterSetName='WithBaseCounter')]
        [Diagnostics.PerformanceCounterType]
        # The base performance counter's type (from the Diagnostics.PerformanceCounterType enumeration).
        $BaseType,

        [Switch]
        # Re-create the performance counter even if it already exists.
        $Force
    )

    $currentCounters = @( Get-PerfCounter -CategoryName $CategoryName )

    $counter = $currentCounters |
                    Where-Object {
                        $_.CounterName -eq $Name -and `
                        $_.CounterHelp -eq $Description -and `
                        $_.CounterType -eq $Type
                    }

    if( $counter -and -not $Force)
    {
        return
    }

    if( $PSCmdlet.ParameterSetName -eq 'WithBaseCounter' )
    {
        $baseCounter = $currentCounters |
                        Where-Object {
                            $_.CounterName -eq $BaseName -and `
                            $_.CounterHelp -eq $BaseDescription -and `
                            $_.CounterType -eq $BaseType
                        }

        if( $baseCounter -and -not $Force)
        {
            return
        }
    }
    else
    {
        $BaseName = $null
    }

    $counters = New-Object Diagnostics.CounterCreationDataCollection
    $currentCounters  |
        Where-Object { $_.CounterName -ne $Name -and $_.CounterName -ne $BaseName } |
        ForEach-Object {
            $creationData = New-Object Diagnostics.CounterCreationData $_.CounterName,$_.CounterHelp,$_.CounterType
            [void] $counters.Add( $creationData )
        }

    $newCounterData = New-Object Diagnostics.CounterCreationData $Name,$Description,$Type
    [void] $counters.Add( $newCounterData )


    if( $PSCmdlet.ParameterSetName -eq 'WithBaseCounter' )
    {
        $newBaseCounterData = New-Object Diagnostics.CounterCreationData $BaseName,$BaseDescription,$BaseType
        [void] $counters.Add( $newBaseCounterData )

    }
        Uninstall-PerfCounterCategory -CategoryName $CategoryName
        [void] [Diagnostics.PerformanceCounterCategory]::Create( $CategoryName, $CategoryDescription, $CategoryType,$counters )
        $module.Warn("$($Name) created")
}


$categoryState = $false
try {
  $categoryState = Test-PerfCounterCategory -CategoryName $category -CategoryType $categorytype -CategoryDescription $categorydescription
}
catch {
  $module.FailJson("Failed checking the existing category", $_.Exception)
}

If (($state -eq "absent") -and ($categoryState -eq $true)) {
  try {
    Uninstall-PerfCounterCategory -CategoryName $category
    $module.Result.changed = $true
  }
  catch {
    $module.FailJson("Failed deleting category", $_.Exception)
  }

}

If (($state -eq "present")) {
  $recreateNeeded = !$categoryState
  if (!$recreateNeeded)
  {
    try {
      #check if all counters presents (assuming that they already have the correct settings)
      $counterCollection  | ForEach-Object {
        $counterResult = Test-PerfCounter -CategoryName $category -Name $_.CounterName -Type $_.CounterType -Description $_.CounterDescription
        if(!$counterResult)
        {
          $module.Warn("$($_.CounterName) did not match expected")
        }
        $recreateNeeded = (!$counterResult -or $recreateNeeded)
      }
    }
    catch {
      $module.FailJson("Failed testing existing counters: $($_.Exception.Message)")
    }
  }
  if ($recreateNeeded -eq $true) # recreate them all
  {

    Uninstall-PerfCounterCategory -CategoryName $category

    $counterCollection  | ForEach-Object {
      Install-PerfCounter -CategoryName $category -CategoryType $categorytype -CategoryDescription $categorydescription  -Name $_.CounterName -Description $_.CounterDescription -Type $_.CounterType
      $module.Result.changed = $true
    }
  }
}
$module.ExitJson()
