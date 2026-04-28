#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2019, Giesecke Devrient

DOCUMENTATION = r'''
---
module: win_driver_printer
short_description: Install printer driver
description:
  - The win_driver_printer module can install a driver.
author:
  - Giesecke Devrient
options:
  inf_path:
    type: str
    description: Path to setup information (INF) files
    required: true
  driver_name:
    type: str
    description: Driver name
    required: true
  printer_env:
    type: str
    description: Operating environments that the driver is intended for.
    choices:
      - x64
      - x86
    default: x64
  state:
    description:
      - When present, install the driver.
      - When absent, removes the driver if it exists.
    type: str
    default: present
    choices:
      - present
      - absent
'''


EXAMPLES = r"""
- name: Install Printer Driver
  gi_de.system.win_driver_printer:
    inf_path: C:\Windows\inf
    driver_name: Generic / Text Only
    state: present
"""
RETURN = r'''
'''
