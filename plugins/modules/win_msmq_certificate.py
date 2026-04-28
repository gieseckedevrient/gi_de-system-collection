#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2020, Giesecke Devrient

DOCUMENTATION = r'''
---
module: win_msmq_certificate
version_added: ""
short_description: Generate MSMQ internal certificate
description:
  - Generate MSMQ internal certificate
options:
  state:
    description:
      - When present, creates or updates the certificate.
      - When absent, removes the certificate.
    type: str
    default: present
    choices:
      - present
      - absent
author:
  - Giesecke Devrient
'''

EXAMPLES = r'''
- name: Ensure internal msmq certificate exist for PDPG service account
  gi_de.system.win_msmq_certificate:
    state: present
  become: true
  become_method: runas
  vars:
    ansible_become_user: "{{ gi_de_pdpg_corecomponents_domain_name_netbios }}\\{{ gi_de_pdpg_corecomponents_managed_service_account }}"
    ansible_become_password:
'''

RETURN = r'''
#
'''
