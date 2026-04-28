#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2019, Giesecke Devrient

DOCUMENTATION = r'''
---
module: win_driver_store
short_description: Add driver package to windows driver store
description:
  - Add driver package to windows driver store
author:
  - Giesecke Devrient



options:
  url:
    type: str
    description: Link to cab package containing the driver. required when O(is_local) is false.
  name:
    type: str
    required: true
    description: Driver name
  state:
    description:
      - When present, install the driver.
      - When absent, removes the driver if it exists.
    type: str
    default: present
    choices:
      - present
      - absent
  is_local:
    type: bool
    description: if drivers is using local inf file
    default: false
    version_added: "6.15.0"
  inf_path:
    type: str
    description: path to local driver .inf file. required when O(is_local) is true.
    version_added: "6.15.0"
'''


EXAMPLES = r"""
- name: Add driver to windows DriverStore
  gi_de.system.win_driver_store:
    url: https//nexus/repository/Microsoft/Driver/Printer/Generic/TextOnly/6.1.7600.16385/4745_b71b6fcc3d1b83b569cd738e6bdc2f591a205b14.cab
    name: Generic / Text Only
    state: present
- name: Add HP UPD driver to windows DriverStore
  gi_de.system.win_driver_store:
    inf_path: "C:\\temp\\HP_UPD\\hpcu180t.inf"
    is_local: true
    name: hpcu180t
    state: present
"""
RETURN = r'''
'''
