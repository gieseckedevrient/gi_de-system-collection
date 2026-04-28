#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2023, Giesecke Devrient

DOCUMENTATION = r'''
---
module: win_wellknownsid_info
short_description: Get a wellknown SID details
description:
  - This module will read the local definition af a WellKnown SID
options:
  name:
    description:
      - the name of Well known to be fetch
    type: str
    default: Most
    choices:
      - Most
      - AccountAdministrator
      - AccountCertAdmins
      - AccountComputers
      - AccountControllers
      - AccountDomainAdmins
      - AccountDomainGuests
      - AccountDomainUsers
      - AccountEnterpriseAdmins
      - AccountGuest
      - AccountKrbtgt
      - AccountPolicyAdmins
      - AccountRasAndIasServers
      - AccountSchemaAdmins
      - Anonymous
      - AuthenticatedUser
      - Batch
      - BuiltinAccountOperators
      - BuiltinAdministrators
      - BuiltinAuthorizationAccess
      - BuiltinBackupOperators
      - BuiltinDomain
      - BuiltinGuests
      - BuiltinIncomingForestTrustBuilders
      - BuiltinNetworkConfigurationOperators
      - BuiltinPerformanceLoggingUsers
      - BuiltinPerformanceMonitoringUsers
      - BuiltinPowerUsers
      - BuiltinPreWindows2000CompatibleAccess
      - BuiltinPrintOperators
      - BuiltinRemoteDesktopUsers
      - BuiltinReplicator
      - BuiltinSystemOperators
      - BuiltinUsers
      - CreatorGroupServer
      - CreatorGroup
      - CreatorOwnerServer
      - CreatorOwner
      - Dialup
      - DigestAuthentication
      - EnterpriseControllers
      - Interactive
      - LocalService
      - Local
      - LocalSystem
      - LogonIds
      - MaxDefined
      - NetworkService
      - Network
      - NTAuthority
      - NtlmAuthentication
      - ProxySid	14Indicates a proxy SID
      - RemoteLogonId
      - RestrictedCode
      - SChannelAuthentication
      - Self
      - Service
      - TerminalServer
      - ThisOrganization
      - WinAccountReadonlyControllers
      - WinApplicationPackageAuthority
      - WinBuiltinAnyPackage
      - WinBuiltinCertSvcDComAccessGroup
      - WinBuiltinCryptoOperators
      - WinBuiltinDCOMUsers
      - WinBuiltinEventLogReadersGroup
      - WinBuiltinIUsers
      - WinBuiltinTerminalServerLicenseServers
      - WinCacheablePrincipalsGroup
      - WinCapabilityDocumentsLibrary
      - WinCapabilityEnterpriseAuthentication
      - WinCapabilityInternetClientServer
      - WinCapabilityInternetClient
      - WinCapabilityMusicLibrary
      - WinCapabilityPicturesLibrary
      - WinCapabilityPrivateNetworkClientServer
      - WinCapabilityRemovableStorage
      - WinCapabilitySharedUserCertificates
      - WinCapabilityVideosLibrary
      - WinConsoleLogon
      - WinCreatorOwnerRights
      - WinEnterpriseReadonlyControllers
      - WinHighLabel
      - WinIUser
      - WinLocalLogon
      - WinLowLabel
      - WinMediumLabel
      - WinMediumPlusLabel
      - WinNewEnterpriseReadonlyControllers
      - WinNonCacheablePrincipalsGroup
      - WinSystemLabel
      - WinThisOrganizationCertificate
      - WinUntrustedLabel
      - WinWriteRestrictedCode
      - World
author:
  - Giesecke Devrient
'''

EXAMPLES = r'''
- name: Get Most frequent WellKnownSID
  gi_de.system.win_wellknownsid_info:
    name: "Most"
  register: _role_win_wellknownsid_info

- name: Get Most frequent WellKnownSID
  gi_de.system.win_wellknownsid_info:
  register: _role_win_wellknownsid_info

# PRODUCES
# ok: [targethost] => {
#     "_role_win_wellknownsid_info": {
#         "changed": false,
#         "exists": true,
#         "failed": false,
#         "msg": "Captured Wellknown :BuiltinAdministratorsSid, BuiltinUsersSid, BuiltinPerformanceLoggingUsersSid,
#                 BuiltinPerformanceMonitoringUsersSid, WinBuiltinEventLogReadersGroup, BuiltinRemoteDesktopUsersSid",
#         "wellknown": {
#             "BuiltinAdministrators": {
#                 "domain": "BUILTIN",
#                 "fullname": "BUILTIN\\Administrators",
#                 "isaccountsid": false,
#                 "name": "Administrators",
#                 "sid": "S-1-5-32-544"
#             },
#             "BuiltinPerformanceLoggingUsers": {
#                 "domain": "BUILTIN",
#                 "fullname": "BUILTIN\\Performance Log Users",
#                 "isaccountsid": false,
#                 "name": "Performance Log Users",
#                 "sid": "S-1-5-32-559"
#             },
#             "BuiltinPerformanceMonitoringUsers": {
#                 "domain": "BUILTIN",
#                 "fullname": "BUILTIN\\Performance Monitor Users",
#                 "isaccountsid": false,
#                 "name": "Performance Monitor Users",
#                 "sid": "S-1-5-32-558"
#             },
#             "BuiltinRemoteDesktopUsers": {
#                 "domain": "BUILTIN",
#                 "fullname": "BUILTIN\\Remote Desktop Users",
#                 "isaccountsid": false,
#                 "name": "Remote Desktop Users",
#                 "sid": "S-1-5-32-555"
#             },
#             "BuiltinUsers": {
#                 "domain": "BUILTIN",
#                 "fullname": "BUILTIN\\Users",
#                 "isaccountsid": false,
#                 "name": "Users",
#                 "sid": "S-1-5-32-545"
#             },
#             "WinBuiltinEventLogReadersGroup": {
#                 "domain": "BUILTIN",
#                 "fullname": "BUILTIN\\Event Log Readers",
#                 "isaccountsid": false,
#                 "name": "Event Log Readers",
#                 "sid": "S-1-5-32-573"
#             }
#         }
#     }
# }

- name: Get specific WellKnown SID
  gi_de.system.win_wellknownsid_info:
    name: BuiltinPerformanceLoggingUsers
  register: _role_win_wellknownsid_performance_users

# PRODUCES
# ok: [target] => {
#     "_role_win_wellknownsid_performance_users": {
#         "changed": false,
#         "exists": true,
#         "failed": false,
#         "msg": "Captured Wellknown :BuiltinPerformanceLoggingUsersSid",
#         "wellknown": {
#             "BuiltinPerformanceLoggingUsers": {
#                 "domain": "BUILTIN",
#                 "fullname": "BUILTIN\\Performance Log Users",
#                 "isaccountsid": false,
#                 "name": "Performance Log Users",
#                 "sid": "S-1-5-32-559"
#             }
#         }
#     }
# }







'''

RETURN = r'''
exists:
  type: bool
  description: if requested WellKnownSID has been found
msg:
  type: str
  description: simple message listing the recovered SIDs
wellknown:
  description: list of captures wellknown SID
  type: list
  elements: dict
  contains:
    wellknown_itself:
      description: the inner name of the wellknown
      type: dict
      contains:
        domain:
          type: str
          description: the domain part of the wellknown fullname
        fullname:
          type: str
          description: the full name captured for the wellknown sid
        isaccountsid:
          type: bool
          description:
        name:
          type: str
          description: the wellknown name part of the fullname
        sid:
          type: str
          description: the SID
'''
