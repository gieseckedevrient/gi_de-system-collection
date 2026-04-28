#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2023, Giesecke Devrient

DOCUMENTATION = r"""
---
module: win_wsfc_group
short_description: Manage clustered roles (resource groups) in a failover cluster.
description:
  - Manage clustered roles (resource groups) in a failover cluster.
author:
  - Giesecke Devrient
options:
  cluster:
    description:
      - Specifies the name of the cluster on which to run this module.
      - If the input for this parameter is . or it is omitted, then the cmdlet runs on the local cluster.
    default: .
    type: str
  name:
    description:
      - List of clustered role to manage.
    required: true
    type: list
    elements: str
  state:
    description:
      - The desired state of the resource.
      - C(started)/C(stopped)/C(moved) are idempotent actions
        that will not run commands unless necessary.
      - C(restarted) will always bounce the resource.
    type: str
    choices: [ started, stopped, restarted, moved ]
    default: moved
  node:
    description:
      - Specifies the name of the cluster node to which to move the resource group.
      - If this argument is omitted, move from the current owner node to any other node.
    type: str
requirements:
  - FailoverClusters powershell module
notes:
"""

EXAMPLES = r"""
- name: Restart SQL Server (INSTANCE)
  gi_de.system.win_wsfc_group:
    name: SQL Server (INSTANCE)
    state: restarted
"""

RETURN = r"""
"""
