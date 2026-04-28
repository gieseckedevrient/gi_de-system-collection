#!powershell

#AnsibleRequires -PowerShell Ansible.ModuleUtils.SID
#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
  options             = @{
    location   = @{ type = "str"; choices = "CurrentUser", "LocalMachine"; default = "LocalMachine" }
    store      = @{ type = "str"; choices = "My", "WebHosting"; default = "My" }
    thumbprint = @{ type = "list"; elements = "str" }
    subject    = @{ type = "list"; elements = "str" }
    user       = @{ type = "str"; required = $true }
    type       = @{ type = "str"; choices = "Allow", "Deny"; default = "Allow" }
    rights     = @{ type = "str"; choices = "FullControl", "Read"; required = $true }
    state      = @{ type = "str"; choices = "present", "absent"; default = "present" }
  }
  mutually_exclusive  = @(
    , @('thumbprint', 'subject')
  )
  supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)
$ErrorActionPreference = "Stop"

$module.Result.changed = $false
$checkmode = $module.CheckMode
$state = $module.Params.state

$Location = $module.Params.location
$Store = $module.Params.store
$Thumbprint = $module.Params.thumbprint
$Subject = $module.Params.subject
$User = $module.Params.user
$Type = $module.Params.type
$Rights = $module.Params.rights

function Get-UserSID {
  param(
    [String]$AccountName
  )

  $userSID = $null
  $searchAppPools = $false

  if ($AccountName.Split("\").Count -gt 1) {
    if ($AccountName.Split("\")[0] -eq "IIS APPPOOL") {
      $searchAppPools = $true
      $AccountName = $AccountName.Split("\")[1]
    }
  }

  if ($searchAppPools) {
    Import-Module -Name WebAdministration
    $testIISPath = Test-Path -LiteralPath "IIS:"
    if ($testIISPath) {
      $appPoolObj = Get-ItemProperty -LiteralPath "IIS:\AppPools\$AccountName"
      $userSID = $appPoolObj.applicationPoolSid
    }
  }
  else {
    $userSID = Convert-ToSID -account_name $AccountName
  }

  return $userSID
}

function Get-CertificatePrivateKeyPath {
  param (
    [parameter(Mandatory = $true)]
    [System.Security.Cryptography.X509Certificates.X509Certificate2]
    $Certificate
  )

  if ($null -ne $Certificate.PrivateKey) {
    $keyPath = $env:ProgramData + "\Microsoft\Crypto\RSA\MachineKeys\"
    $keyName = $Certificate.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName
    $keyFullPath = $keyPath + $keyName
  }
  else {
    $keyPath = $env:ProgramData + '\Microsoft\Crypto\Keys\'
    $algorithm = $Certificate.GetKeyAlgorithm()

    if ($algorithm.StartsWith("1.2.840.10045")) {
      $ecdsaKey = [System.Security.Cryptography.X509Certificates.ECDsaCertificateExtensions]::GetECDsaPrivateKey($Certificate)
      $keyName = $ecdsaKey.Key.UniqueName
    }
    elseif ($algorithm.StartsWith("1.2.840.113549")) {
      $rsaKey = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($Certificate)
      $keyName = $rsaKey.Key.UniqueName
    }
    elseif ($algorithm.StartsWith("1.3.14.3.2.12")) {
      $dsaKey = [System.Security.Cryptography.X509Certificates.DSACertificateExtensions]::GetDSAPrivateKey($Certificate)
      $keyName = $dsaKey.Key.UniqueName
    }
    else {
      $module.FailJson("Unknown certificate key algorithm OID $algorithm.")
    }

    $keyFullPath = $keyPath + $keyName
  }

  return $keyFullPath
}

function Test-AccessControlPresent {
  param
  (
    [parameter(Mandatory = $true)]
    [System.Security.AccessControl.FileSecurity]
    $CertificatSecurity,

    [parameter(Mandatory = $true)]
    [System.Security.AccessControl.FileSystemAccessRule]
    $AccessRule
  )

  foreach ($rule in $CertificatSecurity.GetAccessRules($true, $true, [System.Security.Principal.SecurityIdentifier])) {
    if (($rule.AccessControlType -eq $NewAccessRule.AccessControlType) -and
        ($rule.FileSystemRights -eq $NewAccessRule.FileSystemRights) -and
        ($rule.IdentityReference -eq $NewAccessRule.IdentityReference) -and
        ($rule.InheritanceFlags -eq $NewAccessRule.InheritanceFlags) -and
        ($rule.IsInherited -eq $NewAccessRule.IsInherited) -and
        ($rule.PropagationFlags -eq $NewAccessRule.PropagationFlags)) {
      return $true
    }
  }
  return $false
}

# Test that the user/group is resolvable on the local machine
$SID = Get-UserSID -AccountName $User
if (!$SID) {
  $module.FailJson("$User is not a valid user or group on the host machine or domain")
}

# Get list of certificat in specified location, filter on subject/thumbprint if asked.
if ($null -ne $Thumbprint) {
  $Certificates = Get-ChildItem -Path Cert:\$Location\$Store | Where-Object { [String]$_.Thumbprint -in $Thumbprint }
}
elseif ($null -ne $Subject) {
  $Certificates = Get-ChildItem -Path Cert:\$Location\$Store | Where-Object { $_.DnsNameList.Unicode -contains $Subject }
}
else {
  $Certificates = Get-ChildItem -Path Cert:\$Location\$Store
}

if ($null -eq $Certificates) {
  $module.FailJson("No certificates selected, permissions could not be set.")
}

try {
  $NewType = [System.Security.AccessControl.AccessControlType]::$Type
  $NewRights = [System.Security.AccessControl.FileSystemRights]::$Rights
  $NewIdentity = [System.Security.Principal.SecurityIdentifier]::new($SID)
  $NewInheritanceFlag = [System.Security.AccessControl.InheritanceFlags]::None
  $NewPropagationFlag = [System.Security.AccessControl.PropagationFlags]::None

  $NewAccessRule = [System.Security.AccessControl.FileSystemAccessRule]::new($NewIdentity, $NewRights, $NewInheritanceFlag, $NewPropagationFlag, $NewType)

  foreach ($Certificate in $Certificates) {

    $keyFullPath = Get-CertificatePrivateKeyPath -Certificate $Certificate
    if (-not (Test-Path $keyFullPath -Type Leaf)) {
      $module.FailJson("Permissions could not be fetched from certificate, unable to determine private key path.")
    }
    $CertificatSecurity = Get-Acl -Path $keyFullPath
    $match = Test-AccessControlPresent -CertificatSecurity $CertificatSecurity -AccessRule $NewAccessRule

    if ($state -eq "present" -And $match -eq $false) {
      try {
          $CertificatSecurity.AddAccessRule($NewAccessRule)
          try {
              Set-ACL -LiteralPath $keyFullPath -AclObject $CertificatSecurity
          }
          catch {
              (Get-Item -LiteralPath $keyFullPath).SetAccessControl($CertificatSecurity)
          }
          $module.Result.changed = $true
      }
      Catch {
        $module.FailJson("an exception occurred when adding the specified rule - $($_.Exception.Message)")
      }
    }
    elseIf ($state -eq "absent" -And $match -eq $true) {
      try {
          $CertificatSecurity.RemoveAccessRule($NewAccessRule)
          (Get-Item -LiteralPath $keyFullPath).SetAccessControl($CertificatSecurity)
          $module.Result.changed = $true
      }
      catch {
        $module.FailJson("an exception occurred when removing the specified rule - $($_.Exception.Message)")
      }
    }
    else {
      # A rule was attempting to be added but already exists
      If ($match -eq $true) {
        $module.Result.msg = "the specified rule already exists"
      }
      # A rule didn't exist that was trying to be removed
      Else {
        $module.Result.msg = "the specified rule does not exist"
      }
    }
  }
}
catch {
  $module.FailJson("an error occurred when attempting to $state $rights permission(s) on $path for $user - $($_.Exception.Message)")
}

$module.ExitJson()
