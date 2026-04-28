#!powershell

# Copyright: (c) 2026, Giesecke+Devrient

#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
    options             = @{
        binding_type           = @{ type = "str"; default = "hostnameport"; choices = @("hostnameport", "ipport") }
        hostname               = @{ type = "str" }
        ip                     = @{ type = "str" }
        port                   = @{ type = "int"; required = $true }
        certificate_hash       = @{ type = "str" }
        certificate_store_name = @{ type = "str"; default = "My" }
        app_id                 = @{ type = "str"; default = "{00000000-0000-0000-0000-000000000000}" }
        validate_certificate   = @{ type = "bool"; default = $false }
        state                  = @{ type = "str"; default = "present"; choices = @("present", "absent", "query") }
    }
    required_if         = @(
        , @("state", "present", @("certificate_hash"))
        , @("binding_type", "hostnameport", @("hostname"))
        , @("binding_type", "ipport", @("ip"))
    )
    mutually_exclusive  = @(
        , @("hostname", "ip")
    )
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)
$ErrorActionPreference = "Stop"

$module.Result.changed = $false

$BindingType = $module.Params.binding_type
$Hostname = $module.Params.hostname
$Ip = $module.Params.ip
$Port = $module.Params.port
$CertificateHash = $module.Params.certificate_hash
$CertificateStoreName = $module.Params.certificate_store_name
$AppId = $module.Params.app_id
$ValidateCertificate = $module.Params.validate_certificate
$State = $module.Params.state
$CheckMode = $module.CheckMode

# Build the binding identifier based on type
if ($BindingType -eq "hostnameport") {
    $BindingTarget = "${Hostname}:${Port}"
    $NetshBindingParam = "hostnameport"
    $NetshShowPattern = '^\s*Hostname:port\s*:\s*(.+):(\d+)\s*$'
}
else {
    $BindingTarget = "${Ip}:${Port}"
    $NetshBindingParam = "ipport"
    $NetshShowPattern = '^\s*IP:port\s*:\s*(.+):(\d+)\s*$'
}

function Get-SslCertBinding {
    param(
        [string]$BindingParam,
        [string]$BindingTarget,
        [string]$BindingType,
        [string]$ShowPattern
    )

    $output = netsh http show sslcert "${BindingParam}=${BindingTarget}" 2>&1
    if ($LASTEXITCODE -ne 0) {
        $outputStr = ($output | Out-String)
        if ($outputStr -match 'The system cannot find the file specified|SSL Certificate bindings:') {
            return $null
        }
        $module.FailJson("Failed to query SSL certificate binding for '${BindingTarget}': $outputStr")
    }

    $binding = @{
        binding_type = $BindingType
    }
    foreach ($line in $output) {
        if ($line -match '^\s*Certificate Hash\s*:\s*(\S+)') {
            $binding.certificate_hash = $Matches[1]
        }
        elseif ($line -match '^\s*Application ID\s*:\s*(\S+)') {
            $binding.app_id = $Matches[1]
        }
        elseif ($line -match '^\s*Certificate Store Name\s*:\s*(\S+)') {
            $binding.certificate_store_name = $Matches[1]
        }
        elseif ($line -match $ShowPattern) {
            if ($BindingType -eq "hostnameport") {
                $binding.hostname = $Matches[1]
            }
            else {
                $binding.ip = $Matches[1]
            }
            $binding.port = [int]$Matches[2]
        }
    }

    if (-not $binding.ContainsKey('certificate_hash')) {
        return $null
    }

    return $binding
}

function Add-SslCertBinding {
    param(
        [string]$BindingParam,
        [string]$BindingTarget,
        [string]$CertHash,
        [string]$StoreName,
        [string]$AppId
    )

    $result = netsh http add sslcert "${BindingParam}=${BindingTarget}" certhash="$CertHash" certstorename="$StoreName" appid="$AppId" 2>&1
    if ($LASTEXITCODE -ne 0) {
        $module.FailJson("Failed to add SSL certificate binding for '$BindingTarget': $result")
    }
}

function Remove-SslCertBinding {
    param(
        [string]$BindingParam,
        [string]$BindingTarget
    )

    $result = netsh http delete sslcert "${BindingParam}=${BindingTarget}" 2>&1
    if ($LASTEXITCODE -ne 0) {
        $module.FailJson("Failed to remove SSL certificate binding for '$BindingTarget': $result")
    }
}

function Test-CertificateExists {
    param(
        [string]$CertHash,
        [string]$StoreName
    )

    $cert = Get-ChildItem -Path "Cert:\LocalMachine\$StoreName\$CertHash" -ErrorAction SilentlyContinue
    if ($null -eq $cert) {
        $module.FailJson("Certificate with thumbprint '$CertHash' not found in store 'LocalMachine\$StoreName'. Ensure the certificate is imported before binding.")
    }
    if ((Get-Date) -gt $cert.NotAfter) {
        $module.Warn("Certificate '$CertHash' in store '$StoreName' has expired on $($cert.NotAfter.ToString('o'))")
    }
}

# Validate input formats
if ($State -eq "present" -and $CertificateHash -notmatch '^[0-9a-fA-F]{40}$') {
    $module.FailJson("Invalid certificate_hash '$CertificateHash'. Expected a 40-character hexadecimal SHA-1 thumbprint.")
}
if ($AppId -notmatch '^\{[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}\}$') {
    $module.FailJson("Invalid app_id '$AppId'. Expected a GUID in the format '{xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}'.")
}

# Validate certificate if requested
if ($ValidateCertificate -and $State -eq "present" -and $null -ne $CertificateHash) {
    Test-CertificateExists -CertHash $CertificateHash -StoreName $CertificateStoreName
}

# Get current binding
$currentBinding = Get-SslCertBinding -BindingParam $NetshBindingParam -BindingTarget $BindingTarget -BindingType $BindingType -ShowPattern $NetshShowPattern

if ($State -eq "query") {
    if ($null -ne $currentBinding) {
        $module.Result.binding = $currentBinding
        $module.Result.msg = "SSL certificate binding found for '$BindingTarget'"
    }
    else {
        $module.Result.binding = @{}
        $module.Result.msg = "No SSL certificate binding found for '$BindingTarget'"
    }
    $module.ExitJson()
}

if ($State -eq "present") {
    if ($null -ne $currentBinding) {
        # Binding exists — check if it matches
        if ($currentBinding.certificate_hash -eq $CertificateHash -and
            $currentBinding.certificate_store_name -eq $CertificateStoreName -and
            $currentBinding.app_id -eq $AppId) {
            # Already up to date
            $module.Result.binding = $currentBinding
            $module.Result.msg = "SSL certificate binding already up to date"
            $module.ExitJson()
        }

        # Binding exists but differs — remove first, then re-add
        $module.Result.changed = $true
        if (-not $CheckMode) {
            Remove-SslCertBinding -BindingParam $NetshBindingParam -BindingTarget $BindingTarget
            Add-SslCertBinding -BindingParam $NetshBindingParam -BindingTarget $BindingTarget -CertHash $CertificateHash -StoreName $CertificateStoreName -AppId $AppId
        }
        $module.Result.msg = "SSL certificate binding updated for '$BindingTarget'"
    }
    else {
        # No binding — create one
        $module.Result.changed = $true
        if (-not $CheckMode) {
            Add-SslCertBinding -BindingParam $NetshBindingParam -BindingTarget $BindingTarget -CertHash $CertificateHash -StoreName $CertificateStoreName -AppId $AppId
        }
        $module.Result.msg = "SSL certificate binding added for '$BindingTarget'"
    }

    if (-not $CheckMode) {
        $module.Result.binding = Get-SslCertBinding -BindingParam $NetshBindingParam -BindingTarget $BindingTarget -BindingType $BindingType -ShowPattern $NetshShowPattern
    }
    else {
        # Return the desired state during check mode
        $expectedBinding = @{
            binding_type           = $BindingType
            port                   = $Port
            certificate_hash       = $CertificateHash
            certificate_store_name = $CertificateStoreName
            app_id                 = $AppId
        }
        if ($BindingType -eq "hostnameport") {
            $expectedBinding.hostname = $Hostname
        }
        else {
            $expectedBinding.ip = $Ip
        }
        $module.Result.binding = $expectedBinding
    }
}

if ($State -eq "absent") {
    if ($null -ne $currentBinding) {
        $module.Result.changed = $true
        if (-not $CheckMode) {
            Remove-SslCertBinding -BindingParam $NetshBindingParam -BindingTarget $BindingTarget
        }
        $module.Result.msg = "SSL certificate binding removed for '$BindingTarget'"
    }
    else {
        $module.Result.msg = "No SSL certificate binding found for '$BindingTarget', nothing to remove"
    }
    $module.Result.binding = @{}
}

$module.ExitJson()
