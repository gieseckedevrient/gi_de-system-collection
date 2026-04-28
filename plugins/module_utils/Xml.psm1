# https://github.com/ansible-collections/community.windows

function Copy-Xml($dest, $src, $xmlorig) {
  if ($src.get_NodeType() -eq "Text") {
    $dest.set_InnerText($src.get_InnerText())
  }

  if ($src.get_HasAttributes()) {
    foreach ($attr in $src.get_Attributes()) {
      $dest.SetAttribute($attr.get_Name(), $attr.get_Value())
    }
  }

  if ($src.get_HasChildNodes()) {
    foreach ($childnode in $src.get_ChildNodes()) {
      if ($childnode.get_NodeType() -eq "Element") {
        $newnode = $xmlorig.CreateElement($childnode.get_Name(), $xmlorig.get_DocumentElement().get_NamespaceURI())
        Copy-Xml -dest $newnode -src $childnode -xmlorig $xmlorig
        $dest.AppendChild($newnode) | Out-Null
      }
      elseif ($childnode.get_NodeType() -eq "Text") {
        $dest.set_InnerText($childnode.get_InnerText())
      }
    }
  }
}

function Compare-XmlDocs($actual, $expected) {
  if ($actual.get_Name() -ne $expected.get_Name()) {
    throw "Actual name not same as expected: actual=" + $actual.get_Name() + ", expected=" + $expected.get_Name()
  }
  ##attributes...

  if (($actual.get_NodeType() -eq "Element") -and ($expected.get_NodeType() -eq "Element")) {
    if ($actual.get_HasAttributes() -and $expected.get_HasAttributes()) {
      if ($actual.get_Attributes().Count -ne $expected.get_Attributes().Count) {
        throw "attribute mismatch for actual=" + $actual.get_Name()
      }
      for ($i = 0; $i -lt $expected.get_Attributes().Count; $i = $i + 1) {
        if ($expected.get_Attributes()[$i].get_Name() -ne $actual.get_Attributes()[$i].get_Name()) {
          throw "attribute name mismatch for actual=" + $actual.get_Name()
        }
        if ($expected.get_Attributes()[$i].get_Value() -ne $actual.get_Attributes()[$i].get_Value()) {
          throw "attribute value mismatch for actual=" + $actual.get_Name()
        }
      }
    }

    if (($actual.get_HasAttributes() -and !$expected.get_HasAttributes()) -or (!$actual.get_HasAttributes() -and $expected.get_HasAttributes())) {
      throw "attribute presence mismatch for actual=" + $actual.get_Name()
    }
  }

  ##children
  if ($expected.get_ChildNodes().Count -ne $actual.get_ChildNodes().Count) {
    throw "child node mismatch. for actual=" + $actual.get_Name()
  }

  for ($i = 0; $i -lt $expected.get_ChildNodes().Count; $i = $i + 1) {
    if (-not $actual.get_ChildNodes()[$i]) {
      throw "actual missing child nodes. for actual=" + $actual.get_Name()
    }
    Compare-XmlDocs $expected.get_ChildNodes()[$i] $actual.get_ChildNodes()[$i]
  }

  if ($expected.get_InnerText()) {
    if ($expected.get_InnerText() -ne $actual.get_InnerText()) {
      throw "inner text mismatch for actual=" + $actual.get_Name()
    }
  }
  elseif ($actual.get_InnerText()) {
    throw "actual has inner text but expected does not for actual=" + $actual.get_Name()
  }
}


function Save-ChangedXml($xmlorig, $result, $message, $check_mode, $backup) {
  $result.changed = $true
  if (-Not $check_mode) {
    if ($backup) {
      $result.backup_file = Backup-File -path $dest -WhatIf:$check_mode
      # Ensure backward compatibility (deprecate in future)
      $result.backup = $result.backup_file
    }
    $xmlorig.Save($dest)
    $result.msg = $message
  }
  else {
    $result.msg += " check mode"
  }
}

$export_members = @{
  Function = "Copy-Xml", "Compare-XmlDocs", "Save-ChangedXml"
}
Export-ModuleMember @export_members
