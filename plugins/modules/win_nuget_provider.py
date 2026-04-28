#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2020, Giesecke Devrient

DOCUMENTATION = r'''
---
module: win_nuget_provider
version_added: "1.3.8"
short_description: Register sources to pull nuget packages
description:
  - Register sources to pull nuget packages
options:
  name:
    description: the register Source registered
    type: str
    required: true
  url:
    description: url of the nuget repository (required if state present)
    type: str
  state:
    description:
      - When present, creates or updates the package sources.
      - When absent, removes the record.
    type: str
    default: present
    choices:
      - present
      - absent
author: Giesecke Devrient
'''

EXAMPLES = r'''
- name: Register NuGet provider
  win_nuget_provider:
    name: AutoNuget
    url: "{{ gd_nuget_repository_url }}"
    state: present
'''

RETURN = r'''
#
'''
