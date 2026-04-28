#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2023, Giesecke Devrient

DOCUMENTATION = r"""
---
module: win_adfs_application_permission
short_description: Create-Remove a permission between a client application and web api application in ADFS.
description:
  - Create-Remove a permission between a client application and a web api application in ADFS.
options:
  clientApplicationName:
    description:
      - Specifies the client application name.
    required: true
    type: str
  webApiApplicationName:
    description:
      - Specifies the web api application name.
    required: true
    type: str
  scopeNames:
    description:
      - Specifies an array of scope names.
    type: list
    elements: str
  state:
    description:
      - When present add the permission in ADFS.
      - When absent remove the permission from ADFS.
    default: present
    choices:
      - present
      - absent
    type: str
requirements:
  - ADFS powershell module
extends_documentation_fragment:
  - gi_de.system.dependency
"""

EXAMPLES = r"""
- name: Create a permission in ADFS
  gi_de.system.win_adfs_application_permission:
    clientApplicationName: "SackagerWebApp"
    webApiApplicationName: "SackagerServer"
    scopeNames:
      - "openid"
      - "profil"

- name: Remove a permission in ADFS
  gi_de.system.win_adfs_application_permission:
    clientApplicationName: "SackagerWebApp"
    webApiApplicationName: "SackagerServer"
    state: absent
"""

RETURN = r"""
"""
