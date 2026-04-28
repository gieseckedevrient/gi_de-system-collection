#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2024, Giesecke Devrient

DOCUMENTATION = r"""
---
module: win_smb_closefile
short_description: Close any SMB connection to given file
version_added: "6.4.0"
description:
  - Search for SMB shared files opened matching given pattern
  - Closes the regarding connections if any
options:
  filepattern:
    description:
      - The pattern to find files with open connection
    required: true
    type: str
seealso:
- name: smbshare powershell commandlets
  description: More information on the used cmdlets
  link: https://learn.microsoft.com/en-us/powershell/module/smbshare/close-smbopenfile?view=windowsserver2019-ps
"""

EXAMPLES = r"""
- name: Close connection to file FileDefDPQV19
  gi_de.system.win_smb_closefile:
    filepattern: "FileDefDPQV19"
"""

RETURN = r"""
sessions:
  type: list
  elements: dict
  description: list of session closed
  contains:
    Path:
      type: str
      description: file path having its session closed
    SessionId:
      type: str
      description: ID of the session closed
    ClientComputerName:
      type: str
      description:  SMB client computer name
    ClientUserName:
      type: str
      description: SMB Client username
msg:
  type: str
  description: details of the action performed
"""
