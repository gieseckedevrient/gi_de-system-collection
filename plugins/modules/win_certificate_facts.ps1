#!powershell

#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
  options             = @{
    location       = @{ type = "str"; choices = "CurrentUser", "LocalMachine"; required = $true }
    store          = @{ type = "str"; choices = "AuthRoot", "CA", "My", "Root", "TrustedPeople", "TrustedPublisher", "WebHosting"; required = $true }
    thumbprint     = @{ type = "str" }
    subject        = @{ type = "list"; elements = "str" }
    valid          = @{ type = 'bool'; default = $true }
    withprivatekey = @{ type = 'bool'; default = $true }
  }
  mutually_exclusive  = @(
    , @('thumbprint', 'subject')
  )
  supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$Location = $module.Params.location
$Store = $module.Params.store
$Thumbprint = $module.Params.thumbprint
$Subject = $module.Params.subject
$Valid = $module.Params.valid
$WithPrivateKey = $module.Params.withprivatekey

# Create a new result object
$module.Result.ansible_facts = @{
  ansible_certificates = @()
}

# Get list of certificat in specified location, filter on subject/thumbprint if asked.
if ($null -ne $Thumbprint) {
  $Certificates = Get-ChildItem -Path Cert:\$Location\$Store\$Thumbprint
}
elseif ($null -ne $Subject) {
  $Certificates = Get-ChildItem -Path Cert:\$Location\$Store | Where-Object { $_.DnsNameList.Unicode -contains $Subject }
}
else {
  $Certificates = Get-ChildItem -Path Cert:\$Location\$Store
}

foreach ($Certificate in $Certificates) {
  if (( -not $Valid -or ((Get-Date) -lt $Certificate.NotAfter)) -and ( -not $WithPrivateKey -or $Certificate.HasPrivateKey)) {
    $certificate_info = @{}
    $certificate_info.EnhancedKeyUsageList = $Certificate.EnhancedKeyUsageList.FriendlyName
    $certificate_info.DnsNameList = $Certificate.DnsNameList.Unicode
    $certificate_info.FriendlyName = $Certificate.FriendlyName
    $certificate_info.NotAfter = $Certificate.NotAfter.ToUniversalTime().ToString("o")
    $certificate_info.NotBefore = $Certificate.NotBefore.ToUniversalTime().ToString("o")
    $certificate_info.HasPrivateKey = $Certificate.HasPrivateKey
    $certificate_info.Thumbprint = $Certificate.Thumbprint
    $certificate_info.Issuer = $Certificate.Issuer
    $certificate_info.Subject = $Certificate.Subject
    $module.Result.ansible_facts.ansible_certificates += $certificate_info
  }
}

$module.ExitJson()
