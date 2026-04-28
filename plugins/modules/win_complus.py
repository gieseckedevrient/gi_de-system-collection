#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: Giesecke Devrient

DOCUMENTATION = r'''
---
module: win_complus
short_description: Configure Component services COM+ applications
description:
  - This module will configure an already installed complus application.
options:
  name:
    description:
      - the name of installed application.
    type: str
    required: yes
  identity_username:
    description:
      - The running account to run the Com+ app
    type: string
    required: yes
  identity_password:
    description:
      - Password to of the username. Leave empty if service account
    type: string
  security_accesschecklevel:
    description:
      - "Transaction Access Check Level : COMAdminAccessChecksApplicationLevel = 0, COMAdminAccessChecksApplicationComponentLevel = 1"
    type: int
    choices: [ 0, 1 ]
    default: 1
  security_applicationaccesschecksenforced:
    description:
      - Application Access Check Level
    type: bool
    default: false
  security_impersonationlevel:
    description:
      - Impersionation level for incoming transactions, among
      - COMAdminImpersonationAnonymous = 1
      - COMAdminImpersonationIdentify = 2
      - COMAdminImpersonationImpersonate = 3
      - COMAdminImpersonationDelegate = 4
    type: int
    choices: [ 1,2,3,4 ]
    default: 3
  activation_applicationrootdirectory:
    description:
      - root folder for running the application
    type: str
    default: ""
  components:
    description:
    - List of components to be checked.
    - See the examples on how to format this parameter.
    type: list
    elements: dict
    suboptions:
      name:
        description:
          - root folder for running the application
        type: str
        default: ""
      transactions_transactionsupport:
        description:
          - root folder for running the application
        type: int
        default: 1
      activation_activationcontext:
        description:
          - activation context
        type: str
        default: "Default"
        choices: [ 'Default', 'Client', 'NoForce' ]
      activation_noforce_supportevents:
        description:
          - support events or not
        type: bool
        default: true
      activation_noforce_enablejit:
        description:
          - enable or not JIT
        type: bool
        default: false
      concurrency_synchronization:
        description:
          - COMAdminSynchronizationIgnored = 0
          - COMAdminSynchronizationNone = 1
          - COMAdminSynchronizationSupported = 2
          - COMAdminSynchronizationRequired = 3
          - COMAdminSynchronizationRequiresNew = 4
        type: int
        choices: [ 0, 1, 2, 3, 4 ]
        default: 3
author:
  - Giesecke Devrient
'''

EXAMPLES = r'''
- name: Configure Complus RHSM
  gi_de.system.win_complus:
    name: "RHSM"
    identity_username: "{{ gi_de_cdp_remote_hsm_setup_domain_name_netbios }}\\{{ gi_de_cdp_remote_hsm_setup_managed_service_account }}"
    security_accesschecklevel:  1
    security_applicationaccesschecksenforced: false
    security_impersonationlevel: 3
    activation_applicationrootdirectory: "c:\\windows\\syswow64"
    components:
      - name: "Rhsm.WrapHSM.1"
        transactions_transactionsupport: 1 # Not supported
        activation_activationcontext: NoForce
        concurrency_synchronization: 3  # COMAdminSynchronizationRequired
        activation_noforce_supportevents: true
        activation_noforce_enablejit: true
- name: "Adjust DBA com plus application"
  gi_de.system.win_complus:
    name: "DBA"
    identity_username: "{{ gi_de_cdp_base_setup_domain_name_netbios }}\\{{ gi_de_cdp_base_setup_managed_service_account }}"
    identity_password: "{{ gi_de_cdp_base_setup_service_password | default ('', true) }}"  # ugly but if any further issue with gMSA
  become: true
  become_method: ansible.builtin.runas
'''

RETURN = r'''
msg:
  description: ...
  type: string
'''
