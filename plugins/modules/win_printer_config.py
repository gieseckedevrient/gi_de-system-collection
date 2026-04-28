#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2025, Giesecke Devrient

DOCUMENTATION = r"""
---
module: win_printer_config
version_added: ""
short_description: configure printer settings
description:
  - configure printer settings
author: Giesecke Devrient
version_added: "6.15.0"
options:
  name:
    description:
      - Printer nmae
    type: str
    required: true
  paper_size:
    description: Specifies the paper size the printer uses by default. see L(PrinterConfiguration.PaperSizeEnum,https://learn.microsoft.com/en-us/powershell/module/printmanagement/set-printconfiguration?view=windowsserver2025-ps#-papersize)
    type: str
    choices:
      - Custom
      - Letter
      - LetterSmall
      - Tabloid
      - Ledger
      - Legal
      - Statement
      - Executive
      - A3
      - A4
      - A4Small
      - A5
      - B4
      - B5
      - Folio
      - Quarto
      - Standard10x14
      - Standard11x17
      - Note
      - Number9Envelope
      - Number10Envelope
      - Number11Envelope
      - Number12Envelope
      - Number14Envelope
      - CSheet
      - DSheet
      - ESheet
      - DLEnvelope
      - C5Envelope
      - C3Envelope
      - C4Envelope
      - C6Envelope
      - C65Envelope
      - B4Envelope
      - B5Envelope
      - B6Envelope
      - ItalyEnvelope
      - MonarchEnvelope
      - PersonalEnvelope
      - USStandardFanfold
      - GermanStandardFanfold
      - GermanLegalFanfold
      - IsoB4
      - JapanesePostcard
      - Standard9x11
      - Standard10x11
      - Standard15x11
      - InviteEnvelope
      - LetterExtra
      - LegalExtra
      - TabloidExtra
      - A4Extra
      - LetterTransverse
      - A4Transverse
      - LetterExtraTransverse
      - APlus
      - BPlus
      - LetterPlus
      - A4Plus
      - A5Transverse
      - B5Transverse
      - A3Extra
      - A5Extra
      - B5Extra
      - A2
      - A3Transverse
      - A3ExtraTransverse
      - JapaneseDoublePostcard
      - A6
      - JapaneseEnvelopeKakuNumber2
      - JapaneseEnvelopeKakuNumber3
      - JapaneseEnvelopeChouNumber3
      - JapaneseEnvelopeChouNumber4
      - LetterRotated
      - A3Rotated
      - A4Rotated
      - A5Rotated
      - B4JisRotated
      - B5JisRotated
      - JapanesePostcardRotated
      - JapaneseDoublePostcardRotated
      - A6Rotated
      - JapaneseEnvelopeKakuNumber2Rotated
      - JapaneseEnvelopeKakuNumber3Rotated
      - JapaneseEnvelopeChouNumber3Rotated
      - JapaneseEnvelopeChouNumber4Rotated
      - B6Jis
      - B6JisRotated
      - Standard12x11
      - JapaneseEnvelopeYouNumber4
      - JapaneseEnvelopeYouNumber4Rotated
      - Prc16K
      - Prc32K
      - Prc32KBig
      - PrcEnvelopeNumber1
      - PrcEnvelopeNumber2
      - PrcEnvelopeNumber3
      - PrcEnvelopeNumber4
      - PrcEnvelopeNumber5
      - PrcEnvelopeNumber6
      - PrcEnvelopeNumber7
      - PrcEnvelopeNumber8
      - PrcEnvelopeNumber9
      - PrcEnvelopeNumber10
      - Prc16KRotated
      - Prc32KRotated
      - Prc32KBigRotated
      - PrcEnvelopeNumber1Rotated
      - PrcEnvelopeNumber2Rotated
      - PrcEnvelopeNumber3Rotated
      - PrcEnvelopeNumber4Rotated
      - PrcEnvelopeNumber5Rotated
      - PrcEnvelopeNumber6Rotated
      - PrcEnvelopeNumber7Rotated
      - PrcEnvelopeNumber8Rotated
      - PrcEnvelopeNumber9Rotated
      - PrcEnvelopeNumber10Rotated
  duplexing_mode:
    description: Specifies the duplexing mode the printer uses by default.
    type: str
    choices:
      - OneSided
      - TwoSidedLongEdge
      - TwoSidedShortEdge
  color:
    description: Specifies whether the printer should use either color or grayscale printing by default.
    type: bool
  collate:
    description: Specifies whether to collate the output of the printer by default.
    type: bool

seealso:
  - name: Set-PrintConfiguration cmdlet
    description: more information of the underlying main cmdlet
    link: https://learn.microsoft.com/en-us/powershell/module/printmanagement/set-printconfiguration
"""

EXAMPLES = r"""
- name: Configure printer paper format
  gi_de.system.win_printer_config:
    name: "TestPrinter"
    paper_size: A4
"""

RETURN = r"""
---
msg:
  type: str
  description: simple message saying result
"""
