#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2023, Giesecke Devrient

DOCUMENTATION = r"""
---
module: win_certificate_facts
short_description: Provide information on X.509 certificates available in the local certificate store.
description:
  - This module allows one to query information on certificates available in the local certificate store.
options:
  location:
    description: Specifies the certificate store in which to search.
    required: true
    type: str
    choices:
      - CurrentUser
      - LocalMachine
  store:
    description: Specifies the certificate store in which to search.
    required: true
    type: str
    choices:
      - AuthRoot
      - CA
      - My
      - Root
      - TrustedPeople
      - TrustedPublisher
      - WebHosting
  thumbprint:
    description: Specifies the thumbprint of certificate to query.
    type: str
  subject:
    description: Specifies one or more DNS names contains in the subject alternative name extension of certificates to query.
    type: list
    elements: str
  valid:
    description: Specifies to return information on certificates not expired only.
    type: bool
    default: true
  withprivatekey:
    description: Specifies to return information on certificates with private key only.
    type: bool
    default: true
"""

EXAMPLES = r"""
- name: Get available certificates
  gi_de.system.win_certificate_facts:
    location: LocalMachine
    store: LocalMachine
- name: Get available certificates
  gi_de.system.win_certificate_facts:
    location: LocalMachine
    store: LocalMachine
    subject: myserver.test.local
"""

RETURN = r"""
---
ansible_certificates:
  description: Facts of available X.509 certificates.
  returned: success
  type: list
  elements: dict
  contains:
    EnhancedKeyUsageList:
      description: Possible usages for the public key in the certificate.
      type: list
      elements: str
      sample: ["Client Authentication", "Server Authentication"]
    DnsNameList:
      description:
        - Content from the DNSName entry in the SubjectAlternativeName (SAN) extension.
        - If the SAN extension is empty, the property is populated with content from the Subject field of the certificate.
      type: list
      elements: str
      sample: ["vip.domain.local", "server.domain.local"]
    FriendlyName:
      description: The certificate's friendly name.
      type: str
    NotAfter:
      description: Date after which certificate is no longer valid (ISO 8601).
      type: str
      sample: "2028-05-16T10:30:03.0000000Z"
    NotBefore:
      description: Date after which certificate becomes valid (ISO 8601).
      type: str
      sample: "2023-05-16T10:20:04.0000000Z"
    HasPrivateKey:
      description: The certificate contains a private key.
      type: bool
    Thumbprint:
      description: The thumbprint of the certificate.
      type: str
      sample: "B6E3B9D1EE5BC7E5432D092934F2FC94C757055A"
    Issuer:
      description: The distinguished name of the certificate issuer.
      type: str
      sample: "CN=server.domain.local"
    Subject:
      description: The distinguished name of certificate.
      type: str
      sample: "CN=vip.domain.local"
"""
