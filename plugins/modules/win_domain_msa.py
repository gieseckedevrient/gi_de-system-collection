#!/usr/bin/python
# -*- coding: utf-8 -*-

# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

# this is a windows documentation stub. actual code lives in the .ps1
# file of the same name

DOCUMENTATION = r'''
---
module: win_domain_msa
version_added: '2.4'
short_description: Manages Windows Active Directory Managed Service Accounts
description:
     - Manages Windows Active Directory Managed Service Accounts.
options:
  name:
    description:
      - Name of the account to create, remove or modify.
    required: true
  state:
    description:
      - When C(present), creates or updates the user account.  When C(absent),
        removes the user account if it exists.  When C(query),
        retrieves the user account details without making any changes.
    choices: [ absent, present, query ]
    default: present
  enabled:
    description:
      - C(true) will enable the account.
      - C(false) will disable the account.
    type: bool
    default: 'true'
  description:
    description:
      - Description of the account
  groups:
    description:
      - Adds or removes the user from this list of groups,
        depending on the value of I(groups_action). To remove all but the
        Principal Group, set C(groups=<principal group name>) and
        I(groups_action=replace). Note that users cannot be removed from
        their principal group (for example, "Domain Users").
    type: list
  groups_action:
    description:
      - If C(add), the user is added to each group in I(groups) where not
        already a member.
      - If C(remove), the user is removed from each group in I(groups).
      - If C(replace), the user is added as a member of each group in
        I(groups) and removed from any other groups.
    choices: [ add, remove, replace ]
    default: replace
  path:
    description:
      - Container or OU for the new user; if you do not specify this, the
        user will be placed in the default container for users in the domain.
      - Setting the path is only available when a new user is created;
        if you specify a path on an existing user, the user's path will not
        be updated - you must delete (e.g., state=absent) the user and
        then re-add the user with the appropriate path.
  attributes:
    description:
      - A dict of custom LDAP attributes to set on the user.
      - This can be used to set custom attributes that are not exposed as module
        parameters, e.g. C(telephoneNumber).
      - See the examples on how to format this parameter.
    version_added: '2.5'
  domain_accountname:
    description:
    - The accountname to use when interacting with AD.
    - If this is not set then the user Ansible used to log in with will be
      used instead when using CredSSP or Kerberos with credential delegation.
    version_added: '2.5'
  domain_password:
    description:
    - The password for I(username).
    version_added: '2.5'
  domain_server:
    description:
    - Specifies the Active Directory Domain Services instance to connect to.
    - Can be in the form of an FQDN or NetBIOS name.
    - If not specified then the value is based on the domain of the computer
      running PowerShell.
    version_added: '2.5'
  dnshostname:
    description: Specifies the DNS host name.
  restricttooutboundauthenticationonly:
    type: bool
    default: false
    description:
      - Switch which is used to create a group managed service account which on success can be used by a service
        for successful outbound authentication requests only.
      - This allows creating a group managed service account without the parameters required for successful inbound authentication.
  restricttosinglecomputer:
    type: bool
    default: false
    description:
      - Switch which is used to create a managed service account that can be used only for a single computer.
      - These managed service accounts which are linked to a single computer account were introduced in Windows Server 2008 R2.

  principalsallowedtodelegatetoaccount:
    description:
      - Specifies the accounts which can act on the behalf of users to services running as this Managed Service Account or Group Managed Service Account.
      - This parameter sets the msDS-AllowedToActOnBehalfOfOtherIdentity attribute of the object.
  principalsallowedtoretrievemanagedpassword:
    description:
      - Specifies the membership policy for systems which can use a group managed service account.
      - For a service to run under a group managed service account, the system must be in the membership policy of the account.
      - This parameter sets the msDS-GroupMSAMembership attribute of a group managed service account object.
      - This parameter should be set to the principals allowed to use this group managed service account.


notes:
  - Works with Windows 2012R2 and newer.
  - If running on a server that is not a Domain Controller, credential
    delegation through CredSSP or Kerberos with delegation must be used or the
    I(domain_username), I(domain_password) must be set.
'''

EXAMPLES = r'''
- name: Create group managed service account
  gi_de.system.win_domain_msa:
    name: "ServiceAccount"
    dnshostname: domain.local
    principalsallowedtoretrievemanagedpassword: "CN=ServersGroup,cn=Users,dc=DOMAIN,dc=LOCAL"
    state: present
  become: true
  become_method: ansible.builtin.runas

- name: Create managed service account
  gi_de.system.win_domain_msa:
    name: "ServiceAccount"
    restricttosinglecomputer: true
    state: present
  become: true
  become_method: ansible.builtin.runas

'''

RETURN = r'''
changed:
    description: true if the account changed during execution
    returned: always
    type: bool
    sample: false
description:
    description: A description of the account
    returned: always
    type: str
    sample: Server Administrator
distinguished_name:
    description: DN of the user account
    returned: always
    type: str
    sample: CN=nick,OU=test,DC=domain,DC=local
enabled:
    description: true if the account is enabled and false if disabled
    returned: always
    type: str
    sample: true
groups:
    description: AD Groups to which the account belongs
    returned: always
    type: list
    sample: [ "Domain Admins", "Domain Users" ]
msg:
    description: Summary message of whether the user is present or absent
    returned: always
    type: str
    sample: User nick is present
name:
    description: The username on the account
    returned: always
    type: str
    sample: nick
sid:
    description: The SID of the account
    returned: always
    type: str
    sample: S-1-5-21-2752426336-228313920-2202711348-1175
state:
    description: The state of the user account
    returned: always
    type: str
    sample: present
upn:
    description: The User Principal Name of the account
    returned: always
    type: str
    sample: nick@domain.local
'''
