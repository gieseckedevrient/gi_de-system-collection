#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2023, Giesecke Devrient

DOCUMENTATION = r"""
---
module: win_certificate_generate
short_description: Creates a new self-signed certificate for testing purposes.
description:
  - Creates a new self-signed certificate for testing purposes.
options:
  location:
    description: Specifies the certificate store in which to store the new certificate.
    type: str
    choices:
      - CurrentUser
      - LocalMachine
    default: LocalMachine
  store:
    description: Specifies the certificate store in which to store the new certificate.
    type: str
    choices:
      - My
      - WebHosting
    default: My
  subject:
    description:
      - Specifies one or more DNS names to put into the subject alternative name extension of the certificate.
      - The first DNS name is also saved as the Subject Name.
    required: true
    type: list
    elements: str
  keylength:
    description: Specifies the length, in bits, of the key that is associated with the new certificate.
    type: int
    default: 4096
  keyexportpolicy:
    description: Specifies the policy that governs the export of the private key that is associated with the certificate.
    type: str
    choices:
      - Exportable
      - ExportableEncrypted
      - NonExportable
    default: ExportableEncrypted
  lifetime:
    description:
      - Specifies the life time of the certificate in months.
      - The default value for this parameter is five year after the certificate was created.
    type: int
    default: 60
"""

EXAMPLES = r"""
- name: Generate self signed certificate
  gi_de.system.win_certificate_generate:
    location: LocalMachine
    store: My
    subject: server.domain.local
"""

RETURN = r"""
---
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
