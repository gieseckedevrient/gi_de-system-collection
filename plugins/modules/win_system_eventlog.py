#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2024, Giesecke Devrient

DOCUMENTATION = r"""
---
module: win_system_eventlog
short_description: Enable/Disable windows system event log.
description:
  - This module allows to enable or disable a windows system event log, enable by default.
options:
  name:
    type: str
    description: Event log name to modify
    required: true
  state:
    description:
      - When enable, enable logging.
      - When disable, disable logging.
    default: enable
    choices:
      - enable
      - disable
    type: str
"""

EXAMPLES = r"""
- name: Enable IIS Logging
  gi_de.system.win_system_eventlog:
    name: Microsoft-IIS-Logging/Logs

- name: Disable IIS Logging
  gi_de.system.win_system_eventlog:
    name: Microsoft-IIS-Logging/Logs
    state: disable
"""

RETURN = r"""
#
"""
