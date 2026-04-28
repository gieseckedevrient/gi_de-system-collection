#!powershell

# Copyright: (c) 2020-2024

#AnsibleRequires -CSharpUtil Ansible.Basic
$spec = @{
    options             = @{
        name          = @{ type = 'str'; required = $true }
        dest          = @{ type = 'path'; required = $true }
        source        = @{ type = 'str'; required = $true }
        version       = @{ type = 'str'; required = $true }
        strictVersion = @{ type = 'bool'; required = $false ; default = $true }
        state         = @{ type = 'str'; choices = 'absent', 'present'; default = 'present' }
        retryCount    = @{ type = 'int'; required = $false ; default = 5 }
        retryTime     = @{ type = 'int'; required = $false ; default = 30 }
        skipDeps      = @{ type = 'bool'; required = $false ; default = $false }
    }
    supports_check_mode = $false
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)
$check_mode = $module.CheckMode

$name = $module.Params.name
$dest = $module.Params.dest
$source = $module.Params.source
$version = $module.Params.version
$strictVersion = $module.Params.strictVersion
$retryCount = $module.Params.retryCount
$retryTime = $module.Params.retryTime
$skipDeps = $module.Params.skipDeps
# TODO : get this working
$state = $module.Params.state

$module.Result = @{}
$module.Result.Msg = @{}
# Enable TLS1.1/TLS1.2 if they're available but disabled (eg. .NET 4.5)
$security_protocols = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::SystemDefault
if ([System.Net.SecurityProtocolType].GetMember('Tls11').Count -gt 0)
{
    $security_protocols = $security_protocols -bor [System.Net.SecurityProtocolType]::Tls11
}
if ([System.Net.SecurityProtocolType].GetMember('Tls12').Count -gt 0)
{
    $security_protocols = $security_protocols -bor [System.Net.SecurityProtocolType]::Tls12
}
[System.Net.ServicePointManager]::SecurityProtocol = $security_protocols

Function Test-IsVersion
{
    [OutputType([boolean])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Version
    )
    try
    {
        $version = [Version]::Parse($Version)
        return $true
    }
    catch
    {
        return $false
    }
}
Function Test-NugetPackageSource
{
    [OutputType([boolean])]
    Param (
        [Parameter(Mandatory = $true)]
        [string]$Name
    )
    $NugetPackageSource = Get-PackageSource -Name $Name -ProviderName NuGet -ErrorAction Ignore
    if ($NugetPackageSource)
    {
        return $true
    }
    return $false
}

Function Test-NugetPackage
{
    [OutputType([boolean])]
    Param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$Dest,
        [Parameter(Mandatory = $true)]
        [string]$Version
    )
    $NugetPackage = Get-Package -Name $Name -Destination $Dest -RequiredVersion $Version -ErrorAction Ignore
    if ($NugetPackage)
    {
        return $true
    }
    return $false
}

Function Retry-Command
{
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0, Mandatory = $true)]
        [scriptblock]$ScriptBlock,

        [Parameter(Position = 1, Mandatory = $false)]
        [int]$Maximum = 4,

        [Parameter(Position = 2, Mandatory = $false)]
        [int]$Delay = 15
    )
    Begin
    {
        $Stoploop = $false
        $Retrycount = 1
        $ErrorActionPreferenceToRestore = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'
    }
    Process
    {
        do
        {
            try
            {
                Invoke-Command -Command $ScriptBlock
                $Stoploop = $true
                $ErrorActionPreference = $ErrorActionPreferenceToRestore
                break
            }
            catch
            {
                if ($Retrycount -ge $Maximum)
                {
                    $module.Warn("Fatal fail fetching package after $Retrycount attempts with error : " + $($_.Exception.Message))
                    $ErrorActionPreference = $ErrorActionPreferenceToRestore
                    throw
                }
                else
                {
                    $Retrycount = $Retrycount + 1
                    $module.Warn("Failed fetching package with error : " + $($_.Exception.Message))
                    $module.Warn("Next attempt ($Retrycount/$Maximum) in $Delay seconds")
                    Start-Sleep -Seconds $Delay
                }
            }
        }
        While ($Stoploop -eq $false)
    }
}



try
{
    Import-Module -Name PackageManagement | Out-Null
}
catch
{
    $module.FailJson('Failed to import PackageManagement module. This module must be available.')
}
if ($strictVersion)
{
    if (!(Test-IsVersion -Version $version))
    {
        $module.FailJson("Version $($version) is not a valid version")
    }
}


if (!(Test-NugetPackageSource -Name $source))
{
    $module.Warn("Package source $($source) is not configured, consider using module win_nuget_provider to have it installed")
    $module.FailJson("Package source $($source) is not configured")
}

$exists = Test-NugetPackage -Name $name -Dest $dest -Version $version

$installParams = @{
    Name = $name
    RequiredVersion = $version
    Source  = $source
    Destination = $dest
}
if($skipDeps)
{
  $installParams.SkipDependencies = $true
}

if (!$exists)
{
    try
    {
        Retry-Command -ScriptBlock {
            Install-Package @installParams | Out-Null
        } -Maximum $retryCount -Delay $retryTime
        $module.Result.Msg = "Package name '$($name)' downloaded to '$($dest)\\$($name).$($version)'"
        $module.Result.changed = $true
    }
    catch
    {
        $module.Result.Err = $_.Exception.Message
        $module.FailJson("Failed to install Package '$($name)' version '$($version)' from '$($source)'.
        For Dependency issue. Consider using parameter 'skipDeps' to skip Dependency installation.
        Error details: $($_.Exception.Message)", $_)
    }
}
else
{
    $module.Result.Msg = "Package name '$($name)' already available at '$($dest)\\$($name).$($version)"
    $module.Result.changed = $false
}

$module.ExitJson()
