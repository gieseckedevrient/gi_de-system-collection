#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2023, Giesecke Devrient

DOCUMENTATION = r"""
---
module: win_scmanager_acl
short_description: Update access list on Service Manager, to allow read access for remote user.
description:
  - Update access list on Service Manager, to allow read access for remote user.
options:
  identity:
    description: User or Group to allow access on Service Manager.
    type: str
    required: true
  state:
    description: Specify whether to add C(present) or remove C(absent) the specified access rule.
    type: str
    choices:
      - absent
      - present
    default: present
"""

EXAMPLES = r"""
- name: Add read access to Service Manager
  gi_de.system.win_scmanager_acl:
    identity: NagiosCheck
"""

RETURN = r"""
#
"""
