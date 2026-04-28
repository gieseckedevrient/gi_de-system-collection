#!powershell

# Copyright: (c) 2023, Giesecke Devrient

#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
    options             = @{
        name = @{ type = "str"
            choices    = "AccountAdministrator", "AccountCertAdmins", "AccountComputers", "AccountControllers", "AccountDomainAdmins", "AccountDomainGuests", "AccountDomainUsers", "AccountEnterpriseAdmins", "AccountGuest", "AccountKrbtgt", "AccountPolicyAdmins", "AccountRasAndIasServers", "AccountSchemaAdmins", "Anonymous", "AuthenticatedUser", "Batch", "BuiltinAccountOperators", "BuiltinAdministrators", "BuiltinAuthorizationAccess", "BuiltinBackupOperators", "BuiltinDomain", "BuiltinGuests", "BuiltinIncomingForestTrustBuilders", "BuiltinNetworkConfigurationOperators", "BuiltinPerformanceLoggingUsers", "BuiltinPerformanceMonitoringUsers", "BuiltinPowerUsers", "BuiltinPreWindows2000CompatibleAccess", "BuiltinPrintOperators", "BuiltinRemoteDesktopUsers", "BuiltinReplicator", "BuiltinSystemOperators", "BuiltinUsers", "CreatorGroupServer", "CreatorGroup", "CreatorOwnerServer", "CreatorOwner", "Dialup", "DigestAuthentication", "EnterpriseControllers", "Interactive", "LocalService", "Local", "LocalSystem", "LogonIds", "MaxDefined", "NetworkService", "Network", "NTAuthority", "NtlmAuthentication", "ProxySid", "RemoteLogonId", "RestrictedCode", "SChannelAuthentication", "Self", "Service", "TerminalServer", "ThisOrganization", "WinBuiltinEventLogReadersGroup", "WinBuiltinTerminalServerLicenseServers", "World", "Most"
            # BROKENS: "WinAccountReadonlyControllers","WinApplicationPackageAuthority","WinBuiltinAnyPackage","WinBuiltinCertSvcDComAccessGroup","WinBuiltinCryptoOperators","WinBuiltinDCOMUsers","WinBuiltinIUsers","WinCacheablePrincipalsGroup","WinCapabilityDocumentsLibrary","WinCapabilityEnterpriseAuthentication","WinCapabilityInternetClientServer","WinCapabilityInternetClient","WinCapabilityMusicLibrary","WinCapabilityPicturesLibrary","WinCapabilityPrivateNetworkClientServer","WinCapabilityRemovableStorage","WinCapabilitySharedUserCertificates","WinCapabilityVideosLibrary","WinConsoleLogon","WinCreatorOwnerRights","WinEnterpriseReadonlyControllers","WinHighLabel","WinIUser","WinLocalLogon","WinLowLabel","WinMediumLabel","WinMediumPlusLabel","WinNewEnterpriseReadonlyControllers","WinNonCacheablePrincipalsGroup","WinSystemLabel","WinThisOrganizationCertificate","WinUntrustedLabel","WinWriteRestrictedCode","
            default    = "Most"
        }
    }
    supports_check_mode = $false
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)
$name = $module.Params.name

$module.Result.changed = $false
$module.Result.exists = $false

function Get-MachineSID {
    <#
        .Notes
            courtesy to @IISResetMe from https://blog.iisreset.me/identifying-well-known-security-principals-with-confidence/
    #>
    param(
        [switch]
        $DomainSID
    )

    $WmiComputerSystem = Get-WmiObject -Class Win32_ComputerSystem
    $IsDomainController = $WmiComputerSystem.DomainRole -ge 4

    if ($DomainSID -or $IsDomainController) {
        $Domain = $WmiComputerSystem.Domain
        $SIDBytes = ([ADSI]"LDAP://$Domain").objectSid | ForEach-Object { $_ }
        $ByteOffset = 0
        New-Object System.Security.Principal.SecurityIdentifier -ArgumentList ([Byte[]]$SIDBytes), $ByteOffset
    }
    else {
        $LocalAccountSID = Get-WmiObject -Query "SELECT SID FROM Win32_UserAccount WHERE LocalAccount = 'True'" | Select-Object -First 1 -ExpandProperty SID
        $MachineSID = ($p = $LocalAccountSID -split "-")[0..($p.Length - 2)] -join "-"
        New-Object System.Security.Principal.SecurityIdentifier -ArgumentList $MachineSID
    }
}
function Get-WellKnwonSidByName {
    <#
        .DESCRIPTION
            Returns the SID from a WellKnownSid Name

        .PARAMETER WellKnownName
            WellKnownName to seek for
        .PARAMETER MachineSID
            Machine context to use

        .OUTPUT
            System.Security.Principal.SecurityIdentifier

    #>
    [OutputType('System.Security.Principal.SecurityIdentifier')]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.Security.Principal.WellKnownSidType]$WellKnownName,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.Security.Principal.SecurityIdentifier]$MachineSID
    )
    New-Object System.Security.Principal.SecurityIdentifier -ArgumentList $WellKnownName, $MachineSID

    # domain-SID is mandatory for any of the below SIDs :
    #   AccountAdministratorSid
    #   AccountGuestSid
    #   AccountKrbtgtSid
    #   AccountDomainAdminsSid
    #   AccountDomainUsersSid
    #   AccountDomainGuestsSid
    #   AccountComputersSid
    #   AccountControllersSid
    #   AccountCertAdminsSid
    #   AccountSchemaAdminsSid
    #   AccountEnterpriseAdminsSid
    #   AccountPolicyAdminsSid
    #   AccountRasAndIasServersSid.
    #  from :
    #
    # https://learn.microsoft.com/en-us/dotnet/api/system.security.principal.securityidentifier.-ctor?redirectedfrom=MSDN&view=net-7.0#system-security-principal-securityidentifier-ctor(system-security-principal-wellknownsidtype-system-security-principal-securityidentifier)


}

function Get-WellKnownSidById {
    [OutputType('System.Security.Principal.SecurityIdentifier')]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$SID
    )
    New-Object System.Security.Principal.SecurityIdentifier -ArgumentList $SID
}


# Some do not work on workstation, as per https://github.com/dotnet/runtime/issues/30020
$brokenList = @("WinAccountReadonlyControllersSid", "WinApplicationPackageAuthoritySid", "WinBuiltinAnyPackageSid", "WinBuiltinCertSvcDComAccessGroup",
    "WinBuiltinCryptoOperatorsSid", "WinBuiltinDCOMUsersSid", "WinBuiltinEventLogReadersGroup", "WinBuiltinIUsersSid", "WinCacheablePrincipalsGroupSid",
    "WinCapabilityDocumentsLibrarySid", "WinCapabilityEnterpriseAuthenticationSid", "WinCapabilityInternetClientServerSid", "WinCapabilityInternetClientSid",
    "WinCapabilityMusicLibrarySid", "WinCapabilityPicturesLibrarySid", "WinCapabilityPrivateNetworkClientServerSid", "WinCapabilityRemovableStorageSid",
    "WinCapabilitySharedUserCertificatesSid", "WinCapabilityVideosLibrarySid", "WinConsoleLogonSid", "WinCreatorOwnerRightsSid", "WinEnterpriseReadonlyControllersSid",
    "WinHighLabelSid", "WinIUserSid", "WinLocalLogonSid", "WinLowLabelSid", "WinMediumLabelSid", "WinMediumPlusLabelSid", "WinNewEnterpriseReadonlyControllersSid",
    "WinNonCacheablePrincipalsGroupSid", "WinSystemLabelSid", "WinThisOrganizationCertificateSid", "WinUntrustedLabelSid", "WinWriteRestrictedCodeSid")
$BrokenSids = @{
    # Based on https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/manage/understand-security-identifiers
    # WinAccountReadonlyControllersSid = ''
    # WinApplicationPackageAuthoritySid = ''
    # WinBuiltinAnyPackageSid = ''
    WinBuiltinCertSvcDComAccessGroup = 'S-1-5-32-574'
    WinBuiltinCryptoOperatorsSid     = 'S-1-5-32-569'
    WinBuiltinDCOMUsersSid           = 'S-1-5-32-562'
    WinBuiltinEventLogReadersGroup   = 'S-1-5-32-573'
    WinBuiltinIUsersSid              = 'S-1-5-32-568'
    # WinCacheablePrincipalsGroupSid = ''
    # WinCapabilityDocumentsLibrarySid = ''
    # WinCapabilityEnterpriseAuthenticationSid = ''
    # WinCapabilityInternetClientServerSid = ''
    # WinCapabilityInternetClientSid = ''
    # WinCapabilityMusicLibrarySid = ''
    # WinCapabilityPicturesLibrarySid = ''
    # WinCapabilityPrivateNetworkClientServerSid = ''
    # WinCapabilityRemovableStorageSid = ''
    # WinCapabilitySharedUserCertificatesSid = ''
    # WinCapabilityVideosLibrarySid = ''
    # WinConsoleLogonSid = ''
    # WinCreatorOwnerRightsSid = ''
    # WinEnterpriseReadonlyControllersSid = ''
    # WinHighLabelSid = ''
    WinIUserSid                      = 'S-1-5-17'
    # WinLocalLogonSid = ''
    # WinLowLabelSid = ''
    # WinMediumLabelSid = ''
    # WinMediumPlusLabelSid = ''
    # WinNewEnterpriseReadonlyControllersSid = ''
    # WinNonCacheablePrincipalsGroupSid = ''
    # WinSystemLabelSid = ''
    # WinThisOrganizationCertificateSid = ''
    # WinUntrustedLabelSid = ''
    # WinWriteRestrictedCodeSid = ''
}

# Handle the 'Most' default value to provide relevant set of variable wellknown SID
$mostList = @("BuiltinAdministratorsSid", "BuiltinUsersSid", "BuiltinPerformanceLoggingUsersSid", "BuiltinPerformanceMonitoringUsersSid",
    "WinBuiltinEventLogReadersGroup", "BuiltinRemoteDesktopUsersSid", "WinBuiltinDCOMUsersSid")
$workingList = @()
if ($name -eq "Most") {
    $workingList += $mostList
}
else {
    $workingList += if ($name -eq "WinBuiltinEventLogReadersGroup" ) { $name } else { $name + "Sid" } # seriously, only one without this 'Sid' suffix ...
}


# Get Machine Id
try {
    $MachineSID = Get-MachineSID
}
catch {
    $module.FailJson("Error fetching Mchine Id: $($_.Exception.Message)", $_)
}


$OutputResultObj = New-Object -TypeName PSCustomObject
try {
    foreach ($wellknown in $workingList) {
        $wellknownSid = if ($brokenList -contains $wellknown) {
            # fallback using only ID because dome do not work on workstation, as per https://github.com/dotnet/runtime/issues/30020
            Get-WellKnownSidById -SID $BrokenSids[$wellknown]
        }
        else {
            #regular thanks to context and Enum
            Get-WellKnwonSidByName -WellKnownName $wellknown -MachineSID $MachineSID
        }
        # if this fails, see trouble shooting https://techcommunity.microsoft.com/t5/ask-the-directory-services-team/troubleshooting-sid-translation-failures-from-the-obvious-to-the/ba-p/399491
        $fullname = $wellknownSid.Translate([System.Security.Principal.NTAccount]).Value

        $OutputObj = New-Object -TypeName PSCustomObject
        $OutputObj | Add-Member -MemberType NoteProperty -Name "sid" -Value $wellknownSid.Value
        $OutputObj | Add-Member -MemberType NoteProperty -Name "isaccountsid" -Value $wellknownSid.IsAccountSid()
        $OutputObj | Add-Member -MemberType NoteProperty -Name "fullname" -Value $fullname
        $OutputObj | Add-Member -MemberType NoteProperty -Name "domain" -Value $fullname.Split("\")[0]
        $OutputObj | Add-Member -MemberType NoteProperty -Name "name" -Value $fullname.Split("\")[1]
        $OutputResultObj | Add-Member -MemberType NoteProperty -Name $wellknown.Replace("Sid", "") -Value $OutputObj
    }
}
catch {
    $module.FailJson("Error fetching WellKnown ($($workingList -join ', ')): $($_.Exception.Message)", $_)
}
$module.Result.msg += "Captured Wellknown :" + ($workingList -join ', ')
$module.Result.exists = $true
$module.Result.wellknown = $OutputResultObj



$module.ExitJson()
