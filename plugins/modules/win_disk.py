#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2019, Giesecke Devrient <sylvain.audie@gi-de.com>

DOCUMENTATION = r"""
---
module: win_disk
short_description: The win_disk module can enable, initialize a disk
description:
  - The win_disk module can enable, initialize a disk
options:
  number:
    type: int
    description: Disk number
    required: true
  partition_style_set:
    type: str
    description: Partition style
    default: gpt
    choices:
      - gpt
      - mbr
"""

EXAMPLES = r"""
- name: Put disks online and initialize it
  gi_de.system.win_disk:
    number: 1
    partition_style_set: gpt
"""

RETURN = r"""
#
"""
