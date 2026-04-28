#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: Giesecke Devrient

DOCUMENTATION = r'''
---
module: win_rdmsg
short_description: Send message to remote desktop logged in users
description:
  - Send message to remote desktop logged in users
version_added: '6.3.5'
options:
  title:
    description:
      - the title off the popup
    type: str
    required: yes
  msg:
    description: content of message of the popup
    type: str
    required: false
  graceperiod:
    type: int
    description: how long to wait before exiting after sending the message, if any session found
author:
  - Giesecke Devrient
'''
EXAMPLES = r"""
- name: Warn logged in users of impending upgrade
  gi_de.system.win_rdmsg:
    title: "INCOMING ANSIBLE UPGRADE : Save and disconnect"
    msg: "Automatic update about to start, please save your work and disconnect. You will be logged of automatically in 45s"
    graceperiod: 45
"""
RETURN = r'''
'''
