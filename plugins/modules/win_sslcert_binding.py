#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2026, Giesecke+Devrient

DOCUMENTATION = r"""
---
module: win_sslcert_binding
short_description: Manage SSL certificate bindings on Windows using netsh http sslcert
description:
  - Add, remove, or query SSL certificate bindings on Windows.
  - Uses C(netsh http) to manage SSL certificate bindings.
  - Supports both C(hostnameport) and C(ipport) binding types.
  - Supports idempotent operations — will only change bindings when the current state differs from the desired state.
options:
  binding_type:
    description:
      - The type of SSL binding to manage.
      - C(hostnameport) binds a certificate to a hostname and port combination (SNI-based).
      - C(ipport) binds a certificate to an IP address and port combination.
    type: str
    choices:
      - hostnameport
      - ipport
    default: hostnameport
  hostname:
    description:
      - The hostname for the SSL binding.
      - Required when I(binding_type=hostnameport).
    type: str
  ip:
    description:
      - The IP address for the SSL binding.
      - Use C(0.0.0.0) to bind to all IPv4 addresses.
      - Required when I(binding_type=ipport).
    type: str
  port:
    description:
      - The port number for the SSL binding.
    type: int
    required: true
  certificate_hash:
    description:
      - The thumbprint (hash) of the certificate to bind.
      - Required when I(state=present).
    type: str
  certificate_store_name:
    description:
      - The name of the certificate store where the certificate is located.
    type: str
    default: My
  app_id:
    description:
      - A GUID identifying the application that owns the binding.
      - Must be in the format C({xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}).
      - If not provided, a default GUID is used.
    type: str
    default: "{00000000-0000-0000-0000-000000000000}"
  validate_certificate:
    description:
      - When C(true), verifies that a certificate with the specified I(certificate_hash) exists
        in the given I(certificate_store_name) before attempting to bind.
      - Helps fail early with a clear message if the certificate is missing or expired.
    type: bool
    default: false
  state:
    description:
      - C(present) ensures the SSL binding exists with the specified certificate.
      - C(absent) ensures the SSL binding is removed.
      - C(query) returns the current binding information without making changes.
    type: str
    choices:
      - present
      - absent
      - query
    default: present
"""

EXAMPLES = r"""
- name: Bind SSL certificate to hostname and port (SNI)
  gi_de.system.win_sslcert_binding:
    hostname: myserver.domain.local
    port: 443
    certificate_hash: B6E3B9D1EE5BC7E5432D092934F2FC94C757055A
    certificate_store_name: My
    state: present

- name: Bind SSL certificate to IP and port
  gi_de.system.win_sslcert_binding:
    binding_type: ipport
    ip: 0.0.0.0
    port: 443
    certificate_hash: B6E3B9D1EE5BC7E5432D092934F2FC94C757055A
    state: present

- name: Bind with certificate validation
  gi_de.system.win_sslcert_binding:
    hostname: myserver.domain.local
    port: 443
    certificate_hash: B6E3B9D1EE5BC7E5432D092934F2FC94C757055A
    validate_certificate: true
    state: present

- name: Remove SSL certificate binding
  gi_de.system.win_sslcert_binding:
    hostname: myserver.domain.local
    port: 443
    state: absent

- name: Query existing SSL certificate binding
  gi_de.system.win_sslcert_binding:
    hostname: myserver.domain.local
    port: 443
    state: query
"""

RETURN = r"""
msg:
  description: Describes the action taken or current state.
  returned: always
  type: str
  sample: "SSL certificate binding added for 'myserver.domain.local:443'"
binding:
  description: The current or resulting SSL certificate binding details.
  returned: success
  type: dict
  contains:
    binding_type:
      description: The type of binding (hostnameport or ipport).
      type: str
      sample: "hostnameport"
    hostname:
      description: The hostname of the binding (hostnameport only).
      type: str
      sample: "myserver.domain.local"
    ip:
      description: The IP address of the binding (ipport only).
      type: str
      sample: "0.0.0.0"
    port:
      description: The port of the binding.
      type: int
      sample: 443
    certificate_hash:
      description: The thumbprint of the bound certificate.
      type: str
      sample: "B6E3B9D1EE5BC7E5432D092934F2FC94C757055A"
    certificate_store_name:
      description: The certificate store name.
      type: str
      sample: "My"
    app_id:
      description: The application ID of the binding.
      type: str
      sample: "{00000000-0000-0000-0000-000000000000}"
"""
