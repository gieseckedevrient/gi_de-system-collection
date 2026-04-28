#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2020, Giesecke Devrient

DOCUMENTATION = r"""
---
module: win_domain_acl
short_description: Add/Remove access rule on Active Directory object.
description:
  - Add/Remove access rule on Active Directory object.
author:
  - Giesecke Devrient
options:
  path:
    description:
      - Specifie the Active Directory object path using Distinguished Name.
    required: true
    type: str
  user:
    description:
      - User or Group to add specified rights to act on Active Directory object.
      - Can be in the form of an FQDN or NetBIOS name.
    required: true
    type: str
  rights:
    description:
      - The rights/permissions that are to be allowed/denied for the specified user or group on Active Directory object.
      - Can be specified as a comma separated list, e.g. ReadProperty, WriteProperty.
      - Rights can be any right under MSDN ActiveDirectoryRights
      - https://learn.microsoft.com/en-us/dotnet/api/system.directoryservices.activedirectoryrights?view=netframework-4.8.
    required: true
    type: str
  object:
    description:
      - The schema GUID of the object to which the access rule applie https://learn.microsoft.com/en-us/windows/win32/adschema/attributes-all.
    type: str
  type:
    description:
      - Specifies whether an AccessRule object is used to allow or deny access.
    required: true
    choices:
      - allow
      - deny
    type: str
  state:
    description:
      - Specify whether to add present or remove absent the specified access rule.
    default: present
    choices:
      - present
      - absent
    type: str
  inherit:
    description:
      - Inherit flags on the ACL rules.
      - Can be specified as a comma separated list, e.g. ContainerInherit, ObjectInherit.
      - For more information on the choices see MSDN ActiveDirectorySecurityInheritance enumeration
      - at https://learn.microsoft.com/en-us/dotnet/api/system.directoryservices.activedirectorysecurityinheritance?view=netframework-4.8.
    default: ContainerInherit, ObjectInherit
    type: str
requirements:
  - ActiveDirectory powershell module
notes:
"""

EXAMPLES = r"""
- name: Ensure MYGROUP Service accounts is allowed to create object in MSMQ Users organizational unit
  gi_de.system.win_domain_acl:
    path: "AD:\\OU=MSMQ Users,{{ _pci_domainsetup_info.objects[0].DistinguishedName }}"
    user: MYGROUP System
    rights: CreateChild, DeleteChild, ListChildren, ReadProperty, GenericWrite
    type: allow
    state: present

- name: Ensure service account is allowed to register SPN
  gi_de.system.win_domain_acl:
    path: "AD:\\{{ __install_mssql_instances_win_domain_object_info.objects[0].DistinguishedName }}"
    user: NT AUTHORITY\SELF
    rights: Self, ReadProperty, WriteProperty
    object: f3a64788-5306-11d1-a9c5-0000f80367c1
    type: allow
    state: present
"""

RETURN = r"""
"""
