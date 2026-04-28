#
# -*- coding: utf-8 -*-
# Copyright 2025 Giesecke+Devrient
# GNU General Public License v3.0+
# (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)
#

"""
Strip domain part from username
"""

# Make coding more python3-ish
from __future__ import absolute_import, division, print_function

__metaclass__ = type


DOCUMENTATION = """
  name: strip_domain
  author: kujundzz
  version_added: "6.11.0"
  short_description: Strip domain part from username
  description:
    - This plugin strips the domain part from a domain-qualified username.
    - Supports multiple domain formats including 'DOMAIN\\user', 'DOMAIN/user', 'user@domain.tld', and 'user@domain'.
    - Using the parameters below C(username|strip_domain)
  options:
    user_string:
      description:
        - The domain-qualified username
        - This option represents the string value that is passed to the filter plugin in pipe format.
        - For example C(domain_user | strip_domain), in this case C(user_string) represents this option.
      type: str
      required: true
  seealso:
    - name: User Name Formats
      description: The user can specify domain credentials information in one of the following formats.
      link: https://learn.microsoft.com/en-us/windows/win32/secauthn/user-name-formats
"""

EXAMPLES = r"""
  - debug:
      msg: "{{ 'DOMAIN\\user' | gi_de.system.strip_domain }}"
  - debug:
      msg: "{{ 'DOMAIN/user' | gi_de.system.strip_domain }}"
  - debug:
      msg: "{{ 'user@domain.tld' | gi_de.system.strip_domain }}"
  - debug:
      msg: "{{ 'user@domain' | gi_de.system.strip_domain }}"
  - debug:
      msg: "{{ 'user' | gi_de.system.strip_domain }}"
"""

RETURN = r"""
  _value:
    description: username without domain part
    type: str
"""


def strip_domain(user_string):
    """
    Strip domain part from username.

    Strips domain part from:
    - 'DOMAIN\\user'
    - 'DOMAIN/user'
    - 'user@domain.tld'
    - 'user@domain'

    If the input is already 'user', returns it as-is.

    Args:
        user_string (str): A domain-qualified username.

    Returns:
        str: Just the username.
    """
    if not isinstance(user_string, str):
        raise ValueError("Input to strip_domain must be a string")

    user_string = user_string.strip()

    if '\\' in user_string:
        return user_string.split('\\', 1)[1]
    elif '/' in user_string:
        return user_string.split('/', 1)[1]
    elif '@' in user_string:
        return user_string.split('@', 1)[0]
    else:
        return user_string


class FilterModule(object):
    """strip domain from username"""

    def filters(self):
        """a mapping of filter names to functions"""
        return {"strip_domain": strip_domain}