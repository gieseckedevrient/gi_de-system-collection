#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2023, Giesecke Devrient

DOCUMENTATION = r"""
---
module: win_nlb_cluster
short_description: Creates/Update/Remove a NLB cluster on the specified interface that is defined by the network adapter name.
description: Creates/Update/Remove a NLB cluster on the specified interface that is defined by the network adapter name.
version_added: '5.0.0'
author: Giesecke Devrient
options:
  clustername:
    description: Specifies the name of the cluster.
    required: true
    type: str
  clusterip:
    description: Specifies the primary cluster IP address for the cluster.
    required: true
    type: str
  clustersubnetmask:
    description: Table name.
    required: true
    type: str
  dedicatedip:
    description:
      - Specifies the dedicated IP address to use for the node when creating the cluster.
      - If this parameter is omitted, then the existing static IP address on the node is used.
    type: str
  dedicatedipsubnetmask:
    description:
      - Specifies the dedicated IP address subnet mask to use for the node when creating the new cluster.
      - If this parameter is omitted, then the existing static IP address subnet mask on the node will be used.
    type: str
  interfacename:
    description: Specifies the interface to which NLB is bound. This is the interface of the cluster against which this cmdlet is run.
    required: true
    type: str
  operationmode:
    description: Specifies the operation mode for the new cluster.
    default: MULTICAST
    choices:
      - IGMPMULTICAST
      - MULTICAST
      - UNICAST
    type: str
  state:
    description:
      - When present, creates or updates the cluster.
      - When absent, removes the cluster.
    default: present
    choices:
      - present
      - absent
    type: str
"""

EXAMPLES = r"""
- name: Setup NLB cluster
  gi_de.system.win_nlb_cluster:
    clustername: adfs.mydomain.local
    clusterip: 10.10.10.10
    clustersubnetmask: 255.255.255.0
    dedicatedip: 10.10.10.10
    dedicatedipsubnetmask: 255.255.255.0
    interfacename: Ethernet0 2
    operationmode: MULTICAST
    state: present
"""

RETURN = r"""
#
"""
