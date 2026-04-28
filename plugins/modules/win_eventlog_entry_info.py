#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2025, Giesecke Devrient

DOCUMENTATION = r"""
---
module: win_eventlog_entry_info
short_description: read event logs entries
description:
  - read the specified lasts message in event log and return them
version_added: "6.7.0"
options:
  log:
    description: >
      - the event log to target
      - Could by any of the existing EvenLog that may exists on the target host,
      - e.g Application, System, ...
    type: str
    default: Application
  entry_type:
    description: >
      - type of eventlog entries to filter for
    type: list
    elements: str
    choices:
      - Error
      - FailureAudit
      - Information
      - SuccessAudit
      - Warning
    default: Error
  source:
    description: >
      - Source to filter result from
      - omit to not filter per source
    type: str
    required: false
  limit:
    description: max number of results to return
    type: int
    default: 5
  maxageinminutes:
    description:
      - minutes in the past to filter data
      - set to 0 to remove time limitations
    type: int
    default: 5
seealso:
  - name: EventLog powershell commandlets
    description: More information on the used cmdlets
    link: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/get-eventlog
"""

EXAMPLES = r"""
- name: Get Errors-level events in Application eventlog not older than 5 minutes
  gi_de.system.win_eventlog_entry_info:
  register: found
- name: Debug it
  debug:
    var: found


- name: Get Information-level events in System eventlog not older than 10 minutes
  gi_de.system.win_eventlog_entry_info:
    maxageinminutes: 10
    entry_type: Information
    log: System
  register: found
"""

RETURN = r"""
msg:
  type: str
  description: some details of the number of entries found
  sample: >-
    No message found
events:
  description: List of events found
  type: list
  elements: dict
  sample: >-
    EntryType: Information
    EventID: 7036
    Message: "The Windows Insider Service service entered the running state."
    Source: "Service Control Manager"
    TimeGenerated: "3/6/2025 9:40:08 AM"
    UserName: null
  contains:
    TimeGenerated:
      description: datetime
      type: str
      sample: "3/6/2025 9:40:08 AM"
    Source:
      description: source
      type: str
      sample: "Service Control Manager"
    EntryType:
      description: entrytype
      type: str
      sample: Information
    Message:
      description: message content
    UserName:
      description: user raising event
    EventID:
      description: event ID
      type: int
      sample: 7036
"""
