#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2019, Giesecke Devrient

DOCUMENTATION = r'''
---
module: win_domain_kds
short_description: Create the Key Distribution Services KDS Root Key
description:
  - Create the Key Distribution Services KDS Root Key
author:
  - Giesecke Devrient
options:
  state:
    description: Used to specify the state of the key. Use present to specify if the key should be created.
    type: str
    default: present
    choices:
      - present
      - query
'''
EXAMPLES = r"""

- name: Generates a new root key for the Microsoft Group KdsSvc
  gi_de.system.win_domain_kds:
    state: present
"""
RETURN = r'''
'''
