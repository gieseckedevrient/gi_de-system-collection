#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2020, Giesecke Devrient

DOCUMENTATION = r'''
---
module: win_package_facts
version_added: ""
short_description: get Data about msi state on target host.
description:
  - Get Data about msi state on target host.
options:
  name:
    description:
      - name of software installed, supports pattern
    type: str
    required: false
    default: none
    aliases: []
  appGUID:
    description:
      - app GUID
    type: str
    required: false
    default: none
    aliases: []
author: Giesecke Devrient
'''

EXAMPLES = r'''
- name: Check artefact version installed using wildcard pattern
  gi_de.system.win_package_facts:
    name: "RabbitMQ Server .*"
  register: __installed_version
- name: "Check artefact version installed using appGUID"
  gi_de.system.win_package_facts:
    appGUID: "{EDA3FABE-E481-4E69-A7B0-E845DF0FEC22}"
  register: __installed_version
- name: " Check package version installed using name"
  gi_de.system.win_package_facts:
    name: 'RichPDF Production Engine v3.0'
  register: __installed_version
'''

RETURN = r'''
exists:
  type: bool
  description: if requested WellKnownSID has been found
msg:
  type: str
  description: simple message saying result
Packages:
  description: list of captured installed versions of the provided item to seek
  type: list
  elements: dict
  contains:
    AppName:
      description: the installed name
      type: str
    AppVersion:
      description: the installed version
      type: str
    AppVendor:
      description: the vendor
      type: str
    InstalledDate:
      description: if provided, the installed date
      type: str
    UninstallKey:
      description: the registered uninstall instruction
      type: str
    AppGUID:
      description: the appGUID
      type: str
    SoftwareArchitecture:
      description: the architecture guessed from registry location
      type: str
'''
