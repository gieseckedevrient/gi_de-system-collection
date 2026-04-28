#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2023, Giesecke Devrient

DOCUMENTATION = r"""
---
module: win_adfs_web_api_application
short_description: Create/Remove a web api application in ADFS.
description:
  - Create/Remove a web api application in ADFS.
options:
  webApiApplicationName:
    description:
      - Specifies the web api application name.
    required: true
    type: str
  identifier:
    description:
      - Specifies an identifier.
    type: str
  applicationGroupName:
    description:
      - Specifies the application group name.
    type: str
  accessControlPolicyName:
    description:
      - Specifies the name of an access control policy.
    type: str
  tokenLifeTime:
    description:
      - Specifies the token lifetime in minutes.
    type: int
  passNameAndGroupClaim:
    description:
      - Include user name and groups in returned claims to relying party.
    default: true
    type: bool
  state:
    description:
      - When present, add the web api application in ADFS.
      - When absent, remove the web api application from ADFS.
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
- name: Create a web api application in ADFS
  gi_de.system.win_adfs_web_api_application:
    webApiApplicationName: "MyApp"
    identifier: "https://myapp.mydomain.local/"
    applicationGroupName: "WebApplicationGroup"
    accessControlPolicyName: "Permit everyone"
    tokenLifeTime: 10

- name: Remove a web api application in ADFS
  gi_de.system.win_adfs_web_api_application:
    webApiApplicationName: "MyApp"
    state: absent
"""

RETURN = r"""
---
identifier:
  description: web api application identifier added/updated
  returned: if state=present
  type: str
  sample: "127f321a-737b-49f1-a407-da8ed6515c7f"
"""
