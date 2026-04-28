#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2023, Giesecke Devrient

DOCUMENTATION = r"""
---
module: win_certificate_acl
short_description: Update access list on X.509 certificates private key stored in the local certificate store.
description:
  - This module allows to add or remove rights/permissions for a given user or group on X.509 certificates private key stored in the local certificate store.
options:
  location:
    description: Specifies the certificate store location in which to search certificates.
    type: str
    choices:
      - CurrentUser
      - LocalMachine
    default: LocalMachine
  store:
    description: Specifies the certificate store name in which to search certificates.
    type: str
    choices:
      - My
      - WebHosting
    default: My
  thumbprint:
    description: Specifies one or more thumbprint of certificates to update.
    type: list
    elements: str
  subject:
    description: Specifies one or more DNS names contains in the subject alternative name extension of certificates to update.
    type: list
    elements: str
  user:
    description: User or Group to add specified rights to act on certificates private key.
    type: str
    required: true
  type:
    description: Specify whether to allow or deny the rights specified.
    type: str
    choices:
      - Allow
      - Deny
    default: Allow
  rights:
    description: The rights/permissions that are to be allowed/denied for the specified user or group for the certificates private key.
    type: str
    required: true
    choices:
      - FullControl
      - Read
  state:
    description: Specify whether to add C(present) or remove C(absent) the specified access rule.
    type: str
    choices:
      - absent
      - present
    default: present
notes:
  - If adding ACL's for AppPool identities, the Windows Feature "Web-Scripting-Tools" must be enabled.
"""

EXAMPLES = r"""
- name: Add read access to certificate private key
  gi_de.system.win_certificate_acl:
    subject:
      - mywebapp.mydomain.local
    user: MyGroup System
    rights: Read
- name: Add read access to certificate private key
  gi_de.system.win_certificate_acl:
    thumbprint:
      - 1BF170783F23520B22068F39F30A4EB86C322A25
    user: MYUSERNAME
    rights: Read
"""

RETURN = r"""
#
"""
