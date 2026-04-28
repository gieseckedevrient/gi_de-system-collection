#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2023-2023, Giesecke Devrient <sylvain.audie@gi-de.com>

DOCUMENTATION = r"""
---
module: win_service_acl
short_description: Grant specific identities permissions to manage a specific service.
description:
  - Grant specific identities permissions to manage a specific service
  - Any previous permissions are replaced
options:
  services:
    description:
      - The name of the service(s) to grant permissions to
    required: true
    type: list
    elements: str
  identity:
    description:
      - The identity to grant permissions for
    required: true
    type: str
  rights:
    description:
      - permissions to grant
    choices:
      - FullControl
      - QueryConfig
      - ChangeConfig
      - QueryStatus
      - EnumerateDependents
      - Start
      - Stop
      - PauseContinue
      - Interrogate
      - UserDefinedControl
      - Delete
      - ReadControl
      - WriteDac
      - WriteOwner
    default:
      - QueryConfig
      - QueryStatus
      - EnumerateDependents
      - Start
      - Stop
      - PauseContinue
      - Interrogate
      - UserDefinedControl
      - ReadControl
    type: list
    elements: str
  state:
    description:
      - When present, grant the permissions
      - When absent, revoke the permissions
    default: present
    choices:
      - present
      - absent
    type: str
extends_documentation_fragment:
  - gi_de.system.dependency
requirements:
  - Carbon powershell module
"""

EXAMPLES = r"""
- name: Grant permissions to monitor service
  gi_de.system.win_service_acl:
    services:
      - GDGB Crypto Service
      - GDGB Foundation Services
    identity: nagioscheck
    state: present
"""

RETURN = r"""
"""
