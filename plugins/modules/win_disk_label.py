#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2025, Giesecke Devrient

DOCUMENTATION = r"""
---
module: win_disk_label
short_description: Set disk label
description:
  - Set disk label
version_added: "6.10.0"
options:
  driveLetter:
    description:
      - drive to set label for
    required: true
    type: str
  label:
    description: label to ensure
    required: true
    type: str
"""

EXAMPLES = r"""
- name: Set drive D label to Data
  win_disk_label:
    driveLetter: D
    label: Data
"""

RETURN = r"""
msg:
  description: human readable result
  returned: always
  type: str
  sample: "Volume has the already the right label"
"""
