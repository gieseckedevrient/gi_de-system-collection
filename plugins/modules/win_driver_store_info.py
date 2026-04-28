#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2025, Giesecke Devrient

DOCUMENTATION = r'''
---
module: win_driver_store_info
short_description: Get info about installed drivers
description:
  - Get info about installed drivers
author:
  - Giesecke Devrient
version_added: "6.15.0"
options:
  provider:
    type: str
    description: Driver provider
    default: ''
  class_name:
    type: str
    description: Driver class
    default: Printer
'''

EXAMPLES = r"""
- name: Check Available HP Printer drivers
  gi_de.system.win_driver_store_info:
    provider: 'HP'
    class_name: Printer
  register: __install_pcl_driver_found_drivers
"""

RETURN = r"""
msg:
  type: str
  description: some details of the number of drivers found
  sample: >-
    No message found
drivers:
  description: List of drivers found
  type: list
  elements: dict
  sample: >-
    ClassName: "Printer"
    Date: "4/7/2024 12:00:00 AM"
    Driver: "oem11.inf"
    OriginalFileName: C:\\Windows\\System32\\DriverStore\\FileRepository\\hpcu300u.inf_amd64_aefa9c4110ec2905\\hpcu300u.inf"
    ProviderName: "HP"
    Version: "61.300.1.25780"
  contains:
    ClassName:
      description: driver classname
      type: str
      sample: "Printer"
    Date:
      description: install datetime
      type: str
      sample: "3/6/2025 9:40:08 AM"
    Driver:
      description: driver filename as installed
      type: str
      sample: "oem11.inf"
    OriginalFileName:
      description: original driver .inf filename
      type: str
    ProviderName:
      description: driver provider
      type: str
      sample: 'HP'
    Version:
      description: driver version
      type: str
      sample: "61.300.1.25780"

"""
