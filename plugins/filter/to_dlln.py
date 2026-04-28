#
# -*- coding: utf-8 -*-
# Copyright 2023 Giesecke+Devrient
# GNU General Public License v3.0+
# (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)
#

"""
Convert user name to Down-Level Logon Name
"""

# Make coding more python3-ish
from __future__ import absolute_import, division, print_function
from re import escape, match, IGNORECASE

__metaclass__ = type


DOCUMENTATION = """
  name: to_dlln
  author: Giesecke Devrient
  version_added: "4.1.0"
  short_description: Convert user name to Down-Level Logon Name
  description:
    - This plugin converts given user name to Down-Level Logon Name format.
    - Using the parameters below C(username|gi_de.system.to_dlln)
  options:
    username:
      description:
        - The user name
        - This option represents the string value that is passed to the filter plugin in pipe format.
        - For example C(ansible_user | gi_de.system.to_dlln(domain_fqdn) ), in this case C(username) represents this option.
      type: str
      required: true
    domain:
      description:
        - AD DS netbios domain name
      type: str
      required: true
  seealso:
    - name: User Name Formats
      description: The user can specify domain credentials information in one of the following formats.
      link: https://learn.microsoft.com/en-us/windows/win32/secauthn/user-name-formats
"""

EXAMPLES = r"""
  - debug:
      msg:  "{{ ansible_user | gi_de.system.to_dlln('LYS1TST') }}"
"""

RETURN = r"""
  data:
    description: user name in UPN format
    type: str
"""


def to_dlln(username, domain):

    """Convert the user name to down-level logon name."""
    domain_upper = domain.split('.')[0].upper()  # Normalize domain (strip FQDN and uppercase)

    # Already in down-level format
    if match(rf"{escape(domain_upper)}\\.+", username, IGNORECASE):
        return username

    # UPN format
    if match(r".+@.+", username):
        return domain_upper + "\\" + match(r"(.+)@.+", username).group(1)

    # Plain username or other formats
    return domain_upper + "\\" + username


class FilterModule(object):
    """convert to down-level logon name"""

    def filters(self):
        """a mapping of filter names to functions"""
        return {"to_dlln": to_dlln}
