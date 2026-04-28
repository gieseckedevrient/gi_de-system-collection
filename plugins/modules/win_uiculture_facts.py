#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2019, Giesecke Devrient

DOCUMENTATION = r'''
---
module: win_uiculture_facts
short_description: Provide ui culture information
description:
  - Provide ui culture information
author:
  - Giesecke Devrient
'''


EXAMPLES = r"""
- name: Get installed UI culture
  gi_de.system.win_uiculture_facts:
"""
RETURN = r'''
os_installeduiculture_lcid:
  type: str
  description: The culture identifier.
  sample: 1033
os_installeduiculture_name:
  type: str
  description: The culture name in the format languagecode2-country/regioncode2.
  sample: en-US
os_installeduiculture_displayname:
  type: str
  description: The full localized culture name in the format languagefull [country/regionfull].
  sample: Anglais (États-Unis)
'''
