#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2019, Giesecke Devrient

DOCUMENTATION = r'''
---
module: win_domain_organizationalunit
short_description: Manage domain oarganization unit
description:
  - The win_domain_organizationalunit module can add/remove organizational unit in domain
author:
  - Giesecke Devrient
options:
  name:
    type: str
    description: Organizational unit name (required if dn not set)
  path:
    type: str
    description: Path to organizational unit (required if dn not set)
  dn:
    type: str
    description: Distinguished name of organizational unit (required if name and path not set)
  state:
    description: Used to specify the state of the key. Use present to specify if the key should be created.
    type: str
    default: present
    choices:
      - present
      - absent
'''

EXAMPLES = r"""
- name: Ensure the domain OrganizationalUnit exists
  gi_de.system.win_domain_organizationalunit:
    name: UPPT_JobManager
    path: OU=Groupes,DC=mydomain,DC=local
    state: present
"""
RETURN = r'''
'''
