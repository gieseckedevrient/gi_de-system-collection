#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2023, Giesecke Devrient

DOCUMENTATION = r"""
---
module: win_nlb_node
short_description: Creates/Update/Remove a node from NLB cluster on the specified interface that is defined by the network adapter name.
description: Creates/Update/Remove a node from NLB cluster on the specified interface that is defined by the network adapter name.
version_added: '5.0.0'
author: Giesecke Devrient
options:
  existingnodename:
    description: Specifies the name of one of existing node in cluster.
    required: true
    type: str
  existinginterfacename:
    description: Specifies the interface to which NLB is bound on the existing node in cluster.
    required: true
    type: str
  newnodename:
    description: Specifies the name of new node to add in cluster.
    required: true
    type: str
  newinterfacename:
    description: Specifies the interface to which NLB is bound on the new node to add in cluster.
    required: true
    type: str
  state:
    description:
      - When present, add the node in cluster.
      - When absent, remove the node from cluster.
    default: present
    choices:
      - present
      - absent
    type: str
"""

EXAMPLES = r"""
- name: Add node to NLB cluster
  gi_de.system.win_nlb_node:
    existingnodename: adfs.mydomain.local
    existinginterfacename: Ethernet0 2
    newnodename: adfs.mydomain.local
    newinterfacename:  Ethernet0 2
    state: present
"""

RETURN = r"""
#
"""
