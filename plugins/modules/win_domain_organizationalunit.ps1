#!powershell

# Copyright: (c) 2019, Giesecke Devrient

#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
  options = @{
    name = @{ type = "str" }
    path = @{ type = "str" }
    dn = @{ type = "str" }
    state = @{ type = "str"; choices = "absent", "present"; default = "present" }
  }
  supports_check_mode = $true
  mutually_exclusive = @(
    ,@('name', 'dn')
  )
  required_one_of = @(
    ,@('name', 'dn')
  )
  required_together = @(
    ,@('name', 'path')
  )
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)
$module.Result.changed = $false

$name = $module.Params.name
$path = $module.Params.path
$dn = $module.Params.dn
if (-not $dn){
  $dn = "OU=$name,$path"
}
$state = $module.Params.state

function Test-OrganizationalUnitPresent() {
  param ($DistinguishedName)
  try {
    Get-ADOrganizationalUnit -Identity "$DistinguishedName" | Out-Null
    return $true
  }
  catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
    return $false
  }
  catch {
    $module.FailJson("Error on checking if organizationalunit exist: $($_.Exception.Message)")
  }
}

function Remove-OrganizationalUnit() {
  param ($DistinguishedName)
  try {
    Remove-ADOrganizationalUnit -Identity "$DistinguishedName" | Out-Null
  }
  catch {
    $module.FailJson("Error on deleting organizationalunit: $($_.Exception.Message)")
  }
}

function Add-OrganizationalUnit
{
  [CmdletBinding(SupportsShouldProcess=$true)]
  param ($DistinguishedName)

  # A regex to split the DN, taking escaped commas into account
  $DNRegex = '(?<![\\]),'

  # Array to hold each component
  [String[]]$MissingOUs = @()

  # We'll need to traverse the path, level by level, let's figure out the number of possible levels
  $Depth = ($DistinguishedName -split $DNRegex).Count

  # Step through each possible parent OU
  for($i = 1;$i -le $Depth;$i++) {
    $NextOU = ($DistinguishedName -split $DNRegex,$i)[-1]
    if($NextOU.IndexOf("OU=",[StringComparison]"CurrentCultureIgnoreCase") -ne 0 -or [ADSI]::Exists("LDAP://$NextOU")) {
      break
    } else {
      # OU does not exist, remember this for later
      $MissingOUs += $NextOU
    }
  }

  # Reverse the order of missing OUs, we want to create the top-most needed level first
  [array]::Reverse($MissingOUs) | Out-Null

  # Prepare common parameters to be passed to New-ADOrganizationalUnit
  $PSBoundParameters.Remove('DistinguishedName') | Out-Null

  # Now create the missing part of the tree, including the desired OU
  foreach($OU in $MissingOUs)
  {
    $newOUName = (($OU -split $DNRegex,2)[0] -split "=")[1]
    $newOUPath = ($OU -split $DNRegex,2)[1]

    try {
      New-ADOrganizationalUnit -Name $newOUName -Path $newOUPath @PSBoundParameters | Out-Null
    }
    catch {
      $module.FailJson("Error on adding organizationalunit: $($_.Exception.Message)")
    }
  }
}

if ( -not ($state -eq "absent")) {
  if ( -not (Test-OrganizationalUnitPresent -DistinguishedName $dn)) {
    if( -not ($module.CheckMode)) {
      Add-OrganizationalUnit -DistinguishedName $dn
      $module.Result.changed = $true
    }
  }
} else {
  if (Test-OrganizationalUnitPresent -DistinguishedName $dn) {
    if( -not ($module.CheckMode)) {
      Remove-OrganizationalUnit -DistinguishedName $dn
    }
    $module.Result.changed = $true
  }
}

$module.ExitJson()
