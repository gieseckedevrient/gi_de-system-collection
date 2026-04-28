#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2020, Gisecke Devrient
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

ANSIBLE_METADATA = {'metadata_version': '1.1',
                    'status': ['preview'],
                    'supported_by': 'community'}

DOCUMENTATION = r'''
---
module: win_perfmoncounters
short_description: Create Performance monitoring counters and/or delete them
description:
- Create Performance monitoring counters and/or delete them
options:
  category:
    description:
    - name of the category of counters to be created/checked
    type: str
  categorytype:
    description:
    - categorytype
    type: str
    choices:
    - SingleInstance
    - MultiInstance
    default: SingleInstance
  categorydescrption:
    description:
    - description
    type: str
  counters:
    description:
    - List of counters to be created/checked.
    - See the examples on how to format this parameter.
    type: list
    elements: dict
author:
- G.Fauvel
'''

EXAMPLES = r'''
- name: Create 2 counters
  win_perfmoncounters:
    category:  MyTestCategory
    counters:
      - CounterName: ProcessingFileCounter
        CounterType: NumberOfItems32
        CounterDescription: ProcessingFileCounter
      - CounterName: OperationPerSec
        CounterType: RateOfCountsPerSecond64
        CounterDescription: RecordsPerSecond

- name: Deletes the category and any embedded counter
  win_perfmoncounters:
    category:  MyTestCategory
    state: absent

'''

RETURN = r'''
'''
