#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2019-2022, Giesecke Devrient <sylvain.audie@gi-de.com>

DOCUMENTATION = r"""
---
module: win_httpurl_permission
short_description: Grant a user permission to bind to an HTTP URL
description:
  - Uses the HTTP Server API to grant a user permission to bind to an HTTP URL
options:
  url:
    description: The URL
    required: true
    type: str
  principal:
    description: The user receiving the permission. Shall be netbios name like DOMAIN\\USER
    type: str
  permission:
    description: The permission(s) to grant the user
    default: Listen
    choices:
      - Listen
      - Delegate
      - ListenAndDelegate
    type: str
  state:
    description:
      - When present, grant the permissions
      - When absent, revoke the permissions
    default: present
    choices:
      - present
      - absent
      - query
    type: str
extends_documentation_fragment:
  - gi_de.system.dependency
requirements:
  - Carbon powershell module
"""

EXAMPLES = r"""
- name: Grant permissions to bind to url
  win_httpurl_permission:
    url: http://+:8044/GDGB/Services
    principal: LYS1TST\ServiceAccount
    permission: Listen
    state: present
"""

RETURN = r"""
"""
