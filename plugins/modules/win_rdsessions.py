#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: Giesecke Devrient

DOCUMENTATION = r'''
---
module: win_rdsessions
short_description: Disconnect all remote desctop session on running host, excluding console session
description:
  - Disconnect all remote desctop session on running host, excluding console session
author:
  - Giesecke Devrient
'''
EXAMPLES = r"""
- name: Logoff connected users
  gi_de.system.win_rdsessions:
"""
RETURN = r'''
'''
