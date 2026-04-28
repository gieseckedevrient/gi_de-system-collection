#!powershell

#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
    options = @{
        location = @{ type = "str"; choices = "CurrentUser", "LocalMachine"; default = "LocalMachine" }
        store = @{ type = "str"; choices = "My", "WebHosting"; default = "My" }
        subject = @{ type = "list"; elements = "str"; required = $true }
        keylength = @{ type = "int"; default = 4096 }
        keyexportpolicy = @{ type = "str"; choices = "Exportable", "ExportableEncrypted", "NonExportable"; default = "ExportableEncrypted" }
        lifetime = @{ type = "int"; default = 60 }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$Location = $module.Params.location
$Store = $module.Params.store
$Subject = $module.Params.subject
$KeyLength = $module.Params.keylength
$KeyExportPolicy = $module.Params.keyexportpolicy
$NotAfter = (Get-Date).AddMonths($module.Params.lifetime)

$module.Result.changed = $false

# Get list of certificate, matching asked subject, in specified location.
try {
  $Certificates = Get-ChildItem -Path Cert:\$Location\$Store | Where-Object { $_.DnsNameList.Unicode -contains $Subject }
} catch {
  $Module.FailJson("Error when getting certificate list. $($_.Exception.Message)", $_)
}

# Count valid (has private key, and not yet expired) certificate
$ValidCertificateCount = 0
foreach ($Certificate in $Certificates) {
  If (($Certificate.HasPrivateKey) -and ((Get-Date) -lt $Certificate.NotAfter)) {
    $ValidCertificateCount++
  }
}

If ($ValidCertificateCount -eq 0) {
  # No valid certificate available, generate a new one (expect if check mode)
  try {
    $Certificate = New-SelfSignedCertificate -CertStoreLocation "Cert:\$Location\$Store" -DnsName $Subject -KeyLength $KeyLength -KeyExportPolicy $KeyExportPolicy -NotAfter $NotAfter -Type SSLServerAuthentication
  } catch {
    $Module.FailJson("Error when generating certificate. $($_.Exception.Message)", $_)
  }

  $module.Result.EnhancedKeyUsageList = $Certificate.EnhancedKeyUsageList.FriendlyName
  $module.Result.DnsNameList = $Certificate.DnsNameList.Unicode
  $module.Result.FriendlyName = $Certificate.FriendlyName
  $module.Result.NotAfter = $Certificate.NotAfter.ToUniversalTime().ToString("o")
  $module.Result.NotBefore = $Certificate.NotBefore.ToUniversalTime().ToString("o")
  $module.Result.HasPrivateKey = $Certificate.HasPrivateKey
  $module.Result.Thumbprint = $Certificate.Thumbprint
  $module.Result.Issuer = $Certificate.Issuer
  $module.Result.Subject = $Certificate.Subject
  $module.Result.changed = $true

} else {
  # Valid certificate is available, return information in result.
  $module.Result.EnhancedKeyUsageList = $Certificate.EnhancedKeyUsageList.FriendlyName
  $module.Result.DnsNameList = $Certificate.DnsNameList.Unicode
  $module.Result.FriendlyName = $Certificate.FriendlyName
  $module.Result.NotAfter = $Certificate.NotAfter.ToUniversalTime().ToString("o")
  $module.Result.NotBefore = $Certificate.NotBefore.ToUniversalTime().ToString("o")
  $module.Result.HasPrivateKey = $Certificate.HasPrivateKey
  $module.Result.Thumbprint = $Certificate.Thumbprint
  $module.Result.Issuer = $Certificate.Issuer
  $module.Result.Subject = $Certificate.Subject
}

$module.ExitJson()
