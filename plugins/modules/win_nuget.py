#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2022-2024, Giesecke Devrient

DOCUMENTATION = '''
---
module: win_nuget
version_added: "1.3.8"
short_description: download a nuget package from registered source.
description:
     - Download a package using powershell, specifying the source to be used
     - see more on the official doc https://learn.microsoft.com/en-us/powershell/module/packagemanagement/install-package?view=powershell-7.3
options:
  name:
    description:
      - name of nuget package to download
    type: str
    required: yes
  dest:
    description: target folderpath where to put the downloaded nuget package
    type: path
    required: true
  source:
    description: from which registered PackageSource to download the nuget artefact
    type: str
    required: true
  version:
    description: version to be downloaded
    type: str
    required: true
  strictVersion:
    description: checking strict versionning like major. minor[.build[.rev]]
    type: bool
    required: false
    default: true
  state:
    description: When present, downloads if not already available. When absent, removes the pacakge if available.
    type: str
    required: false
    default: present
    choices:
      - present
      - absent
  retryCount:
    description: how many attempts of download to try
    type: int
    required: false
    default: 5
  retryTime:
    description: how many seconds to wait between two download attempts
    type: int
    required: false
    default: 30
  skipDeps:
    description: skip dependancies installation
    type: bool
    required: false
    default: false
author: Giesecke Devrient
'''

EXAMPLES = '''
- name: Download NuGet package
  gi_de.system.win_nuget:
      source: AutoNuget
      name: GieseckeDevrient.Domain.Package
      version: 3.6.0
      dest: C:\\Temp\\

- name: Download NuGet package not strict version
  gi_de.system.win_nuget:
      source: AutoNuget
      name: GieseckeDevrient.Domain.Package
      version: 3.6.0-snapshot
      strictVersion: false
      dest: C:\\Temp\\

- name: Download package from Nuget and skip any dependancy
  gi_de.system.win_nuget:
    source: GDNuget
    name: GieseckeDevrient.Domain.Package
    version: 1.1.0
    dest: C:\\Temp\\
    skipDeps: true
'''
