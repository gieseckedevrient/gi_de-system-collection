#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2023, Giesecke Devrient

DOCUMENTATION = r"""
---
module: win_adfs_native_client_application
short_description: Create/Remove a native client application in ADFS.
description:
  - Create/Remove a native client application in ADFS.
options:
  nativeClientApplicationName:
    description:
      - Specifies the native client application name.
    required: true
    type: str
  applicationGroupName:
    description:
      - Specifies the application group name.
    type: str
  redirectUri:
    description:
      - Specifies the redirect uri of the native client application.
    type: str
  state:
    description:
      - When present, add the native client application in ADFS.
      - When absent, remove the native client application from ADFS.
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
- name: Create a native client application in ADFS
  gi_de.system.win_adfs_native_client_application:
    nativeClientApplicationName: "MyWebApp"
    applicationGroupName: "WebApplicationGroup"
    redirectUri: "https://mywebapp.mydomain3.local/auth"

- name: Remove a native client application in ADFS
  gi_de.system.win_adfs_native_client_application:
    nativeClientApplicationName: "SackagerWebApp"
    state: absent
"""

RETURN = r"""
---
identifier:
  description: native client application identifier added/updated
  returned: if state=present
  type: str
  sample: "127f321a-737b-49f1-a407-da8ed6515c7f"
"""
