#!powershell

# Copyright: (c) 2025, Giesecke Devrient

#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
  options = @{
    name = @{ type = "str"; required = $true }
    paper_size = @{ type = "str";
      choices = "Custom", "Letter", "LetterSmall", "Tabloid", "Ledger", "Legal", "Statement", "Executive", "A3", "A4", "A4Small", "A5", "B4", "B5", "Folio", "Quarto", "Standard10x14", "Standard11x17", "Note", "Number9Envelope", "Number10Envelope", "Number11Envelope", "Number12Envelope", "Number14Envelope", "CSheet", "DSheet", "ESheet", "DLEnvelope", "C5Envelope", "C3Envelope", "C4Envelope", "C6Envelope", "C65Envelope", "B4Envelope", "B5Envelope", "B6Envelope", "ItalyEnvelope", "MonarchEnvelope", "PersonalEnvelope", "USStandardFanfold", "GermanStandardFanfold", "GermanLegalFanfold", "IsoB4", "JapanesePostcard", "Standard9x11", "Standard10x11", "Standard15x11", "InviteEnvelope", "LetterExtra", "LegalExtra", "TabloidExtra", "A4Extra", "LetterTransverse", "A4Transverse", "LetterExtraTransverse", "APlus", "BPlus", "LetterPlus", "A4Plus", "A5Transverse", "B5Transverse", "A3Extra", "A5Extra", "B5Extra", "A2", "A3Transverse", "A3ExtraTransverse", "JapaneseDoublePostcard", "A6", "JapaneseEnvelopeKakuNumber2", "JapaneseEnvelopeKakuNumber3", "JapaneseEnvelopeChouNumber3", "JapaneseEnvelopeChouNumber4", "LetterRotated", "A3Rotated", "A4Rotated", "A5Rotated", "B4JisRotated", "B5JisRotated", "JapanesePostcardRotated", "JapaneseDoublePostcardRotated", "A6Rotated", "JapaneseEnvelopeKakuNumber2Rotated", "JapaneseEnvelopeKakuNumber3Rotated", "JapaneseEnvelopeChouNumber3Rotated", "JapaneseEnvelopeChouNumber4Rotated", "B6Jis", "B6JisRotated", "Standard12x11", "JapaneseEnvelopeYouNumber4", "JapaneseEnvelopeYouNumber4Rotated", "Prc16K", "Prc32K", "Prc32KBig", "PrcEnvelopeNumber1", "PrcEnvelopeNumber2", "PrcEnvelopeNumber3", "PrcEnvelopeNumber4", "PrcEnvelopeNumber5", "PrcEnvelopeNumber6", "PrcEnvelopeNumber7", "PrcEnvelopeNumber8", "PrcEnvelopeNumber9", "PrcEnvelopeNumber10", "Prc16KRotated", "Prc32KRotated", "Prc32KBigRotated", "PrcEnvelopeNumber1Rotated", "PrcEnvelopeNumber2Rotated", "PrcEnvelopeNumber3Rotated", "PrcEnvelopeNumber4Rotated", "PrcEnvelopeNumber5Rotated", "PrcEnvelopeNumber6Rotated", "PrcEnvelopeNumber7Rotated", "PrcEnvelopeNumber8Rotated", "PrcEnvelopeNumber9Rotated", "PrcEnvelopeNumber10Rotated" ;
    }
    duplexing = @{ type = "str";
      choices = "OneSided", "TwoSidedLongEdge", "TwoSidedShortEdge"
    }
    color = @{ type = "bool" }
    collate = @{ type = "bool" }
  }
  supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)
$module.Result.changed = $false

$name = $module.Params.name
$paperSize = $module.Params.paper_size
$duplexing = $module.Params.duplexing
$color = $module.Params.color
$collate = $module.Params.collate

$configParams = @{
    PrinterName  = $name
}


if($null -ne $paperSize)
{
  $configParams['PaperSize'] = $paperSize
}
if($null -ne $duplexing)
{
  $configParams['DuplexingMode'] = $duplexing
}
if($null -ne $color)
{
  $configParams['Color'] = $color
}
if($null -ne $collate)
{
  $configParams['Collate'] = $collate
}

# get current printer config

try
{
  $currentConfig = Get-PrintConfiguration -PrinterName $name
}
catch
{
  $module.FailJson("Failed getting current printer configuration : $($_.Exception.Message)")
}

$need_change = $false

foreach ($key in $configParams.Keys) {
    # Check if the property exists in $currentConfig and compare values
    if ($currentConfig.PSObject.Properties.Name -contains $key) {
        $current = $currentConfig.$key.ToString()
        $target = $configParams[$key].ToString()
        if ($current -ne $target) {
            $need_change = $true
            $module.Result.msg += "diff : $key, `n--- $current`n +++ $target`n"
        }
    } else {
        $module.Result.msg += "Property '$key' does not exist in current configuration."
    }
}

try {
  if ($need_change){
    if(-not $check_mode){
      # splat hashtable to named parameters
      Set-PrintConfiguration @configParams
    }
    $module.Result.changed = $true
  }
  else {
    $module.Result.msg = 'Printer configuration match provided arguments'
  }
}
catch {
  $module.FailJson("Error on updating Printer configuration: $($_.Exception.Message)")
}

$module.ExitJson()
