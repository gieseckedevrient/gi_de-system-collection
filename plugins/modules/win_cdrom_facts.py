#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2019, Giesecke Devrient

DOCUMENTATION = r"""
---
module: win_cdrom_facts
short_description: get fact about optical drive
description:
  - Get fact of optical drive on the machine
"""

EXAMPLES = r"""
- name: Get cdrom facts
  gi_de.system.win_cdrom_facts:
"""

RETURN = r"""
cdrom_driveletter:
  type: str
  description: The drive letter
  sample: "D"
cdrom_drivetype:
  type: str
  description: "CD-ROM"
  sample: "CD-ROM"
cdrom_operationalstatus:
  type: str
  description: TBD
  sample: "Unknown"
cdrom_healthstatus:
  type: str
  description: status
  sample: "Healthy"
cdrom_filesystem:
  type: str
  description: file system type
  sample: ""
cdrom_filesystemlabel:
  type: str
  description: label if any
  sample: ""
cdrom_size:
  type: str
  description: size if any
  sample: "0"
"""
