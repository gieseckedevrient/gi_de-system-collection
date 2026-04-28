#!powershell

# Copyright: (c) 2020, Giesecke Devrient

#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
  options = @{
    state = @{ type = "str"; choices = "absent", "present"; default = "present" }
  }
  supports_check_mode = $false
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$state = $module.Params.state

$module.Result.changed = $false

# Load powershell module
try {
  Import-Module -Name MSMQ
}
catch {
  $module.FailJson("Failed to import MSMQ module. This module must be available.", $_)
}

function Test-MsmqCertificatePresent() {
  try {
    $MsmqCertificate = Get-MsmqCertificate -ComputerName $env:COMPUTERNAME
    If ($MsmqCertificate.Count -eq 0) {
      return $false
    } else {
      $module.Result.EnhancedKeyUsageList = $MsmqCertificate.EnhancedKeyUsageList
      $module.Result.DnsNameList = $MsmqCertificate.DnsNameList
      $module.Result.FriendlyName = $MsmqCertificate.FriendlyName
      $module.Result.NotAfter = $MsmqCertificate.NotAfter
      $module.Result.NotBefore = $MsmqCertificate.NotBefore
      $module.Result.Thumbprint = $MsmqCertificate.Thumbprint
      $module.Result.Issuer = $MsmqCertificate.Issuer
      $module.Result.Subject = $MsmqCertificate.Subject
      return $true
    }
  }
  catch {
    $module.FailJson("Error on checking if MSMQ certificate exist: $($_.Exception.Message)")
  }
}

function Add-MsmqCertificate() {
  try {
    $MsmqCertificate = Enable-MsmqCertificate -RenewInternalCertificate -Confirm:$false
    $module.Result.EnhancedKeyUsageList = $MsmqCertificate.EnhancedKeyUsageList
    $module.Result.DnsNameList = $MsmqCertificate.DnsNameList
    $module.Result.FriendlyName = $MsmqCertificate.FriendlyName
    $module.Result.NotAfter = $MsmqCertificate.NotAfter
    $module.Result.NotBefore = $MsmqCertificate.NotBefore
    $module.Result.Thumbprint = $MsmqCertificate.Thumbprint
    $module.Result.Issuer = $MsmqCertificate.Issuer
    $module.Result.Subject = $MsmqCertificate.Subject
  }
  catch {
    $module.FailJson("Error on adding MSMQ certificate: $($_.Exception.Message)")
  }
}

function Remove-MsmqCertificate() {
  try {
    Get-MsmqCertificate -ComputerName $env:COMPUTERNAME | Remove-MsmqCertificate
    $module.Result.EnhancedKeyUsageList = $null
    $module.Result.DnsNameList = $null
    $module.Result.FriendlyName = $null
    $module.Result.NotAfter = $null
    $module.Result.NotBefore = $null
    $module.Result.Thumbprint = $null
    $module.Result.Issuer = $null
    $module.Result.Subject = $null
  }
  catch {
    $module.FailJson("Error on removing MSMQ certificate: $($_.Exception.Message)")
  }
}

if ( -not ($state -eq "absent")) {
  if ( -not (Test-MsmqCertificatePresent)) {
    if( -not ($module.CheckMode)) {
      Add-MsmqCertificate
      $module.Result.changed = $true
    }
  }
} else {
  if (Test-MsmqCertificatePresent) {
    if( -not ($module.CheckMode)) {
      Remove-MsmqCertificate
    }
    $module.Result.changed = $true
  }
}

$module.ExitJson()
