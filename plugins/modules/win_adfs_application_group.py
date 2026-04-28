#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2023, Giesecke Devrient

DOCUMENTATION = r"""
---
module: win_adfs_application_group
short_description: Create/Remove an application group in ADFS.
description:
  - Create/Remove an application group in ADFS.
options:
  applicationGroupName:
    description:
      - Specifies the application group name to create/remove.
    required: true
    type: str
  state:
    description:
      - When present, add the application group in ADFS.
      - When absent, remove the application group from ADFS.
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
- name: Create application group in ADFS
  gi_de.system.win_adfs_application_group:
    applicationGroupName: "WebApplicationGroup"

- name: Remove application group in ADFS
  gi_de.system.win_adfs_application_group:
    applicationGroupName: "WebApplicationGroup"
    state: absent
"""

RETURN = r"""
"""
