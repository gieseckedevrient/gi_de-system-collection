#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2023, Giesecke Devrient

DOCUMENTATION = r"""
---
module: win_adfs_server_application
short_description: Create/Remove a server application in ADFS.
description:
  - Create/Remove a server application in ADFS.
options:
  server_application_name:
    description:
      - Specifies the server application name.
    required: true
    type: str
  application_group_name:
    description:
      - Specifies the application group name.
    type: str
  redirect_uri:
    description:
      - Specifies the redirect uri of the server application.
    type: str
  ad_user_principal_name:
    description:
      - Specifies the AD user principal name of the server application that will be used to authenticate.
    type: str
  state:
    description:
      - When present, add the server application in ADFS.
      - When absent, remove the server application from ADFS.
    default: present
    choices:
      - present
      - absent
    type: str
requirements:
  - ADFS powershell module
  - Escalation to run the module to access domain users for ad_user_principal_name setup (e.g. ansible.builtin.runas)
extends_documentation_fragment:
  - gi_de.system.dependency
"""

EXAMPLES = r"""
- name: Create a server application in ADFS
  gi_de.system.win_adfs_server_application:
    server_application_name: "MyWebApp"
    application_group_name: "WebApplicationGroup"
    redirect_uri: "https://mywebapp.mydomain.local/auth"
    ad_user_principal_name: "MYDOMAIN\\Service"
  become: true
  become_method: ansible.builtin.runas

- name: Remove a server application in ADFS
  gi_de.system.win_adfs_server_application:
    server_application_name: "MyWebApp"
    state: absent
"""

RETURN = r"""
---
identifier:
  description: server application identifier added/updated
  returned: if state=present
  type: str
  sample: "127f321a-737b-49f1-a407-da8ed6515c7f"
"""
