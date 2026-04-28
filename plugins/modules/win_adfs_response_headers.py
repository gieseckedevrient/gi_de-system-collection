#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2023, Giesecke Devrient

DOCUMENTATION = r"""
---
module: win_adfs_response_headers
short_description: Configure CORS trusted origins from ADFS.
description:
  - Configure CORS trusted origins from ADFS.
options:
  hostName:
    description:
      - Specifies the host name.
    required: true
    type: str
  state:
    description:
      - When present, add the host name in CORS trusted origins from ADFS.
      - When absent, remove the host name in CORS trusted origins from ADFS.
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
- name: Configure CORS trusted origins from ADFS
  gi_de.system.win_adfs_response_headers:
    hostName: "https://mywebapp.mydomain.local"

- name: Remove CORS trusted origins from ADFS
  gi_de.system.win_adfs_response_headers:
    hostName: "https://mywebapp.mydomain.local"
    state: "absent"
"""

RETURN = r"""
"""
