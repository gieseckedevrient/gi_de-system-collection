#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2023, Giesecke Devrient

DOCUMENTATION = r"""
---
module: win_wsfc_group_info
short_description: Query clustered roles (resource groups) in a failover cluster.
description:
  - Query clustered roles (resource groups) in a failover cluster.
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
      - List of clustered role to query.
      - If this argument is omitted, return all clustered role found.
    type: list
    elements: str
requirements:
  - FailoverClusters powershell module
notes:
"""

EXAMPLES = r"""
- name: Get clustered roles state
  gi_de.system.win_wsfc_group_info:

- name: Get SQL Server state
  gi_de.system.win_wsfc_group_info:
    name: SQL Server
"""

RETURN = r"""
exists:
  description: Whether any clustered roles were found based on the criteria specified.
  returned: always
  type: bool
  sample: true
clustergroup:
  description:
    - A list of clustered role(s) that were found based on the criteria.
    - Will be an empty list if no finding.
  returned: always
  type: list
  elements: dict
  contains:
    allowfailback:
      description:
        - Specify whether the clustered role will automatically fail back to the most preferred owner.
      type: bool
      sample: false
    cluster:
      description:
        - Name of the cluster.
      type: str
      sample: mydomain-clu1
    description:
      description:
        - Description.
      type: str
    iscoregroup:
      description:
        - Is Core Cluster Resources.
      type: bool
      sample: false
    lockedfrommoving:
      description:
        - Is locked.
      type: bool
      sample: false
    name:
      description:
        - Name of the clustered role.
      type: str
      sample: SQL Server (SQL)
    state:
      description:
        - State of the clustered role (Failed, Offline, Online, PartialOnline, Pending, Unknown).
      type: str
      sample: Online
"""
