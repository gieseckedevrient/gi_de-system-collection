#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2021, Gisecke Devrient

DOCUMENTATION = r'''
---
module: win_json
short_description: Create, update or delete keys/values in a json file.
description:
  - This module will search a json file for a key/value, and ensure that it is present or absent.
  - Multiple key/value can be provide
options:
  state:
    description:
      - Whether the key should be there or not.
    type: str
    choices: [ absent, present ]
    default: present
  path:
    description:
      - The path of the file to modify.
      - Note that the Windows path delimiter C(\) must be escaped as C(\\) when the line is double quoted.
    type: path
    required: yes
  settings:
    description:
      - Dict of key/value to add/update/delete.
    type: dict
    required: yes
  mode:
    description:
      - Type of value(s) provided
    type: str
    choices: [ Value, ArrayElement ]
    default: Value
  encoding:
    description:
      - Encoding for the JSON file.
    type: str
    choices: [ utf8, utf8NoBOM, utf8BOM, utf32, unicode, bigendianunicode, ascii, sjis, Default ]
    default: utf8NoBOM
  newline:
    description:
      - New line code for the JSON file
    type: str
    choices: [ CRLF, LF ]
    default: CRLF
author:
  - Giesecke Devrient
'''

EXAMPLES = r'''
- name: Update CryptoConfiguration Password
  gi_de.system.win_json:
    state: present
    path: C:\Program Files (x86)\MyAPP\appsettings.json
    settings:
      CryptoConfiguration/Password: AQAAANCMnd8BFdERjHoAwE.................jUmv4g4PnRIchUhtNlRTr
'''

RETURN = r'''
settingsupdated:
  description: List of keys updated
  type: list
settingsdeleted:
  description: List of keys deleted
  returned: if backup=yes
  type: list
'''
