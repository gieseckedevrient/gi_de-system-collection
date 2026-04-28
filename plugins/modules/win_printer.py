#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2019, Giesecke Devrient

DOCUMENTATION = r'''
---
module: win_printer
version_added: ""
short_description: Manage printer
description:
  - Module to add a printer.
options:
  name:
    description:
      - Printer nmae
    type: str
    required: true
  port:
    description: port
    type: str
    required: true
  driver:
    type: str
    required: true
    description: Driver name
  state:
    description:
      - When present, add the printer.
      - When absent, removes the printer if it exists.
    type: str
    default: present
    choices:
      - present
      - absent
author:
  - Giesecke Devrient
'''

EXAMPLES = r'''

- name: Install Printer
  gi_de.system.win_printer:
    name: Nul Printer
    port: nul
    driver: Generic / Text Only
    state: present
'''

RETURN = r'''
#
'''
