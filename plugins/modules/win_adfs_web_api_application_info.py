#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2023, Giesecke Devrient

DOCUMENTATION = r"""
---
module: win_adfs_web_api_application_info
short_description: Get web api application identifier in ADFS.
description:
  - Get web api application identifier in ADFS.
options:
  webApiApplicationName:
    description:
      - Specifies the web api application name.
    required: true
    type: str
requirements:
  - ADFS powershell module
extends_documentation_fragment:
  - gi_de.system.dependency
"""

EXAMPLES = r"""
- name: Get web api application identifier
  gi_de.system.win_adfs_web_api_application_info:
    webApiApplicationName: "SackagerServer"
"""

RETURN = r"""
---
identifier:
  description: web api application identifier
  type: str
  sample: "127f321a-737b-49f1-a407-da8ed6515c7f"
"""
