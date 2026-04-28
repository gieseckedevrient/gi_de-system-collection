#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2023-2023, Giesecke Devrient

# Common options for gi_de.system modules

class ModuleDocFragment(object):
    # Standard documentation
    DOCUMENTATION = r"""
    options:
      carbonversion:
        description: Version of Carbon Module.
        default: '2.15.1'
        type: str
      adfsversion:
        description: Version of ADFS Module.
        default: '1.0.0.0'
        type: str
    """
