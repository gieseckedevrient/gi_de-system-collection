#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2025, Giesecke Devrient

DOCUMENTATION = r"""
---
module: win_printer_facts
version_added: ""
short_description: get details about installed printers.
description:
  - get details about installed printers.
author: Giesecke Devrient

seealso:
  - name: Get-Printer cmdlet
    description: more information of the underlying main cmdlet
    link: https://learn.microsoft.com/en-us/powershell/module/printmanagement/get-printer?view=windowsserver2025-ps
  - name: MSFT_Printer
    description: CIM class MSFT_Printer documentation
    link: https://learn.microsoft.com/en-us/windows/win32/cimwin32prov/cim-printer

"""

EXAMPLES = r"""
- name: Get info about all installed printers
  gi_de.system.win_printer_facts:
  register: __installed_printers
"""

RETURN = r"""
---
exists:
  type: bool
  description: if any printer has been found
msg:
  type: str
  description: simple message saying result
printers:
  description: list of captured installed details of each printer
  type: list
  elements: dict
  contains:
    Name:
      description: Label by which the object is known.
      type: str
      sample: PDFCreator
    Computer:
      description: where it is
      type: str
      sample: ""
    Type:
      description: Local, Remote
      type: str
      sample: Local
    DriverName:
      description: driver used for this
      type: str
      sample: Microsoft XPS Document Writer v4
    PortName:
      description: name of the printing port
      type: str
      sample: "PORTPROMPT:"
    Shared:
      description: is it shared printer
      type: bool
      sample: false
    ShareName:
      description: if share, share name
      type: str
      sample: MYPRINTER
    Published:
      description: published pritner
      type: bool
      sample: false
    KeepPrintedJobs:
      description: KeepPrintedJobs
      type: bool
      sample: false
"""
