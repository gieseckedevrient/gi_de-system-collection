#!powershell

# Copyright: (c) 2020

#AnsibleRequires -CSharpUtil Ansible.Basic
$spec = @{
    options = @{
        name = @{ type = "str"; required = $true }
        url = @{ type = "str" }
        state = @{ type = "str"; choices = "absent", "present"; default = "present"}
    }
    required_if = @(,@("state", "present", @("url")))
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)
$check_mode = $module.CheckMode

$name = $module.Params.name
$url = $module.Params.url
$state = $module.Params.state

$module.Result = @{}
$module.Result.Msg = @{}
# Enable TLS1.1/TLS1.2 if they're available but disabled (eg. .NET 4.5)
$security_protocols = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::SystemDefault
if ([System.Net.SecurityProtocolType].GetMember("Tls11").Count -gt 0) {
    $security_protocols = $security_protocols -bor [System.Net.SecurityProtocolType]::Tls11
}
if ([System.Net.SecurityProtocolType].GetMember("Tls12").Count -gt 0) {
    $security_protocols = $security_protocols -bor [System.Net.SecurityProtocolType]::Tls12
}
[System.Net.ServicePointManager]::SecurityProtocol = $security_protocols


Function Install-NugetProvider {
    Param(
        [Bool]$CheckMode
    )
    $PackageProvider = Get-PackageProvider -ListAvailable | Where-Object { ($_.name -eq 'Nuget') -and ($_.version -ge "2.8.5.201") }
    if (-not($PackageProvider)){
        try {
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -WhatIf:$CheckMode | out-null
        }
        catch [ System.Exception ] {
            $module.Warn("NuGet Package provider is not available. Note that it is installed when running role 'prepare_operatingsystem' from this collection")
            $module.FailJson("Problems adding Nuget package provider: $($_.Exception.Message)")
        }
    }
}

Function Test-NugetPackageSource {
    Param (
        [Parameter(Mandatory=$true)]
        [string]$Name,
        [Parameter(Mandatory=$true)]
        [string]$Url
    )
    $PackageSource = Get-Packagesource -ProviderName NuGet | Where-Object { ($_.name -eq $Name) -and ($_.providername -eq 'NuGet') -and ($_.location -eq $Url) }
    if (-not($PackageSource)){
        return $false
    }
    return $true
}
Function Register-NugetPackageSource {
    Param (
        [Parameter(Mandatory=$true)]
        [string]$Name,
        [Parameter(Mandatory=$true)]
        [string]$Url,
        [Bool]$Trusted,
        [Bool]$CheckMode
    )
    Install-NugetProvider -CheckMode $CheckMode

    $PackageSource = Get-Packagesource -ProviderName NuGet | Where-Object { ($_.name -eq $Name) -and ($_.providername -eq 'NuGet') -and ($_.location -eq $Url) }
    if (-not($PackageSource)){
        try {
            Register-PackageSource -Name $Name -Location $Url -ProviderName NuGet -Trusted | out-null
        }
            catch {
            $ErrorMessage = "Problems registering $($Name) Source: $($_.Exception.Message)"
            $module.FailJson($ErrorMessage)
        }
    }
}

Function Unregister-NugetPackageSource {
    Param (
        [Parameter(Mandatory=$true)]
        [string]$Name
    )
    $PackageSource = Get-Packagesource -ProviderName NuGet | Where-Object { ($_.name -eq $Name) -and ($_.providername -eq 'NuGet') }
    if (($PackageSource)){
        try {
            Unregister-PackageSource -Source $Name | out-null
        }
            catch {
            $ErrorMessage = "Problems unregistering $($Name) Source: $($_.Exception.Message)"
            $module.FailJson($ErrorMessage)
        }
    }
}
# Load powershell module
try {
    Import-Module -Name PackageManagement | out-null
  }
  catch {
    $module.Warn("PackageManagement module must be available. Note this is installed when running role 'prepare_operatingsystem' from this collection")
    $module.FailJson("Failed to import PackageManagement module. This module must be available.")
  }



$exists = Test-NugetPackageSource -Name $name -Url $url


if ($state -eq "present") {
    if($exists)
        {
            $module.Result.Msg = "Package source '$($name)' already registered"
        }
    else{
            Unregister-PackageSource -Name $name -ErrorAction SilentlyContinue #remove any existing if any
            Register-NugetPackageSource -Name $name -Url $url
            $module.Result.changed = $true
            $module.Result.Msg = "Package source '$($name)' registered"
        }
}
elseif ($state -eq "absent") {
    if(!$exists)
    {
        $module.Result.Msg = "Package source '$($name)' already absent"
    }else{
        Unregister-PackageSource -Name $name
        $module.Result.changed = $true
        $module.Result.Msg = "Package source '$($name)' unregistered"
    }
}

$module.ExitJson()
