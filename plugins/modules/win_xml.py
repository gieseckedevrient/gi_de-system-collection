#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2023, Giesecke Devrient

DOCUMENTATION = r'''
---
module: win_xml
short_description: Manages XML file content on Windows hosts
description:
  - Manages XML nodes, attributes and text, using xpath to select which xml nodes need to be managed.
  - XML fragments, formatted as strings, are used to specify the desired state of a part or parts of XML files on remote Windows servers.
  - For non-Windows targets, use the M(community.general.xml) module instead.
options:
  count:
    description:
      - When set to C(yes), return the number of nodes matched by I(xpath).
    type: bool
    default: false
  path:
    description:
      - Path to the file to operate on.
    type: path
    required: true
    aliases: [ dest, file ]
  backup:
    description:
      - Determine whether a backup should be created.
      - When set to C(yes), create a backup file including the timestamp information
        so you can get the original file back if you somehow clobbered it incorrectly.
    type: bool
    default: no
  settings:
    description: list of settings to adjust
    type: list
    elements: dict
    suboptions:
      fragment:
        description:
          - The string representation of the XML fragment expected at xpath. Since ansible 2.9 not required when I(state=absent), or when I(count=yes).
        type: str
        required: false
        aliases: [ xmlstring ]
      attribute:
        description:
          - The attribute name if the type is 'attribute'.
          - Required if C(type=attribute).
        type: str
      state:
        description:
          - Set or remove the nodes (or attributes) matched by I(xpath).
        type: str
        default: present
        choices: [ present, absent ]
      type:
        description:
          - The type of XML node you are working with.
        type: str
        default: element
        choices: [ attribute, element, text ]
      xpath:
        description:
          - Xpath to select the node or nodes to operate on.
        type: str
        required: true
notes:
  - Only supports operating on xml elements, attributes and text.
  - Namespace, processing-instruction, command and document node types cannot be modified with this module.
seealso:
  - module: community.windows.win_xml
    description: XML manipulation for single xpath.
  - name: w3shools XPath tutorial
    description: A useful tutorial on XPath
    link: https://www.w3schools.com/xml/xpath_intro.asp
'''

EXAMPLES = r'''
- name: "Cleanup config file"
  gi_de.system.win_xml:
    settings:
      - xpath: /configuration/applicationSettings/EOSEngineConsole.Settings
        type: element
        state: absent
        fragment: ""
    path: my.exe.confg
  notify: "Restart Service"

- name: "setup an attribute and a text"
  gi_de.system.win_xml:
    settings:
      - xpath: /configuration/nlog/targets/target[@name="xmlfile"]
        attribute: archiveFileName
        fragment: "myspecific.xml"
        type: attribute
      - xpath: /configuration/applicationSettings/EOSEngineLibrary.EncryptionSettings/setting[@name="encryptionKey"]/value
        type: text
        fragment: 1122233545454545
    path: my.exe.confg

- name: "setup a complex element"
  gi_de.system.win_xml:
    settings:
      - xpath: /configuration/applicationSettings
        type: element
        fragment: >-
          <EOSEngineService.Settings>
            <setting name="MQMachines" serializeAs="Xml">
              <value>
                <ArrayOfMQMachine xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
                  {% for rabbit in eos_services_eos_rabbitmq_details %}
                    <MQMachine>
                      <Name>{{ rabbit.host }}</Name>
                      <UserName>{{ rabbit.username }}</UserName>
                      <Pasword>{{ rabbit.password }}</Pasword>
                    </MQMachine>
                  {% endfor %}
                </ArrayOfMQMachine>
              </value>
            </setting>
          </EOSEngineService.Settings>
    path: my.exe.confg

- name: "{{ gd_pci_etl_issuer_plugin_package.name }} - Normalize settings, to update product config (OpenPGP Key)"
  set_fact:
    _etl_issuer_plugin_openpgp_settings:
      - xpath: "/Profile/Extractor/{{ gd_pci_etl_issuer_plugin_package.openpgp.extractor_name }}/PrivateKey"
        attribute: Path
        fragment: "{{ gd_pci_etl_issuer_plugin_package.openpgp.folder }}\\secring.gpg"
        type: attribute
        state: present
      - xpath: "/Profile/Extractor/{{ gd_pci_etl_issuer_plugin_package.openpgp.extractor_name }}/PrivateKey"
        attribute: PrivateKeyId
        fragment: "{{ gd_pci_etl_issuer_plugin_package.openpgp.secretkeyid }}"
        type: attribute
        state: present
      - xpath: "/Profile/Extractor/{{ gd_pci_etl_issuer_plugin_package.openpgp.extractor_name }}/PublicKey"
        attribute: Path
        fragment: "{{ gd_pci_etl_issuer_plugin_package.openpgp.folder }}\\pubring.gpg"
        type: attribute
        state: present
- name: "{{ gd_pci_etl_issuer_plugin_package.name }} - Normalize settings, to update product config (OpenPGP PassPhrase)"
  set_fact:
    _etl_issuer_plugin_openpgp_settings: "{{ _etl_issuer_plugin_openpgp_settings + [{
        'xpath': '/Profile/Extractor/' + gd_pci_etl_issuer_plugin_package.openpgp.extractor_name + '/PrivateKey',
        'attribute': 'PrivateKeyPassword',
        'fragment': _gd_pci_etl_issuer_secretkey_passphrase.ciphered,
        'type': 'attribute',
        'state': 'present'
      }] }}"
  when: _gd_pci_etl_issuer_secretkey_passphrase.changed
- name: "{{ gd_pci_etl_issuer_plugin_package.name }} - Update product config (OpenPGP)"
  gi_de.system.win_xml:
    settings: "{{ _etl_issuer_plugin_openpgp_settings }}"
    path: >-
      {{ pci_etlcore_home_base_folder }}\\Issuer\\{{-
        gd_pci_etl_issuer_plugin_package.issuer }}\\Profile\\{{ gd_pci_etl_issuer_plugin_package.profile }}\\Profile.xml"
  notify: Restart ETL Issuer services
'''

RETURN = r'''
backup_file:
  description: Name of the backup file that was created.
  returned: if backup=yes
  type: str
  sample: C:\\Path\\To\\File.txt.11540.20150212-220915.bak
count:
  description: Number of nodes matched by xpath.
  returned: if count=yes
  type: int
  sample: 33
settingsdeleted:
  description: List of elements updated
  returned: always
  type: list
  sample: ["/Profile/Extractor/caps_DualExtractor/PrivateKey/@PrivateKeyPassword"]
settingsupdated:
  description: List of elements updated
  returned: always, for type element and -vvv or more
  type: list
  sample: ["/Profile/Extractor/caps_DualExtractor/PrivateKey/@PrivateKeyPassword"]
'''
