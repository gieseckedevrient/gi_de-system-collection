#
# -*- coding: utf-8 -*-
# Copyright 2023 Giesecke+Devrient
# GNU General Public License v3.0+
# (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)
#

"""
Convert user name to User Principal Name (UPN)
"""

# Make coding more python3-ish
from __future__ import absolute_import, division, print_function
from re import escape, match

__metaclass__ = type


DOCUMENTATION = """
  name: to_upn
  author: Giesecke Devrient
  version_added: "3.3.0"
  short_description: Convert user name to UPN
  description:
    - This plugin converts given user name to UPN format.
    - Using the parameters below C(username|gi_de.system.to_upn)
  options:
    username:
      description:
        - The user name
        - This option represents the string value that is passed to the filter plugin in pipe format.
        - For example C(ansible_user | gi_de.system.to_upn(domain_fqdn) ), in this case C(username) represents this option.
      type: str
      required: true
    domain:
      description:
        - AD DS fully qualified domain name (FQDN)
      type: str
      required: true
  seealso:
    - name: User Name Formats
      description: The user can specify domain credentials information in one of the following formats.
      link: https://learn.microsoft.com/en-us/windows/win32/secauthn/user-name-formats
"""

EXAMPLES = r"""
  - debug:
      msg:  "{{ ansible_user | gi_de.system.to_upn('mydomain.local') }}"
"""

RETURN = r"""
  data:
    description: user name in UPN format
    type: str
"""


def to_upn(username, domain):
    """Convert the user name to upn."""
    if match(
        r".+@" + escape(domain), username
    ):  # match upn format, already in the right format.
        return username
    elif match(
        r".+\\.+", username
    ):  # match down-level logon name format, convert to upn.
        return match(r".+\\(.+)", username).group(1) + "@" + domain
    else:  # append domain
        return username + "@" + domain


class FilterModule(object):
    """convert to upn"""

    def filters(self):
        """a mapping of filter names to functions"""
        return {"to_upn": to_upn}
