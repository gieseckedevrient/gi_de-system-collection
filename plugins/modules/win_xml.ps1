#!powershell

# Copyright: (c) 2018, Ansible Project
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)
# Copyright: (c) 2021, Giesecke Devrient

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.gi_de.system.plugins.module_utils.Xml
#Requires -Module Ansible.ModuleUtils.Backup

$spec = @{
  options             = @{
    settings = @{
      type        = "list"
      elements    = "dict"
      options     = @{
        xpath     = @{ required = $true; type = "str" }
        attribute = @{ type = "str" }
        fragment  = @{ aliases = "xmlstring"; type = "str" }
        type      = @{ choices = "element", "attribute", "text"; default = "element"; type = "str" }
        state     = @{ type = "str"; default = "present"; choices = "present", "absent" }
      }
      required_if = @(, @("type", "attribute", @("attribute")))
    }
    path     = @{ aliases = "dest", "file"; required = $true; type = "path" }
    backup   = @{ default = $false; type = "bool" }
    count    = @{ default = $false; type = "bool" }
  }
  supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$settings = $module.Params.settings
$dest = $module.Params.path
$backup = $module.Params.backup
$count = $module.Params.count

If (-Not (Test-Path -LiteralPath $dest -PathType Leaf))
{
  $module.FailJson("Specified path $dest does not exist or is not a file.")
}

$xmlorig = New-Object -TypeName System.Xml.XmlDocument
$xmlorig.XmlResolver = $null
Try
{
  $xmlorig.Load($dest)
}
Catch
{
  $module.FailJson("Failed to parse file at '$dest' as an XML document: $($_.Exception.Message)")
}

$XPathsUpdated = @()
$XPathsDeleted = @()

$namespaceMgr = New-Object System.Xml.XmlNamespaceManager $xmlorig.NameTable
$namespace = $xmlorig.DocumentElement.NamespaceURI
$localname = $xmlorig.DocumentElement.LocalName

$namespaceMgr.AddNamespace($xmlorig.$localname.SchemaInfo.Prefix, $namespace)

foreach ($setting in $settings)
{

  $nodeList = $xmlorig.SelectNodes($setting.xpath, $namespaceMgr)
  $nodeListCount = $nodeList.get_Count()
  if ($count)
  {
    $module.Result.xpath[$setting.xpath] += @{count = $nodeListCount }
    if (-not $setting.fragment)
    {
      continue
    }
  }
  ## Exit early if xpath did not match any nodes
  if ($nodeListCount -eq 0)
  {
    $module.Warn($setting.xpath + " did not match any nodes. If this is unexpected, check your xpath is valid for the xml file at supplied path.")
    continue
  }

  if ($setting.type -eq "element")
  {
    if ($setting.state -eq "absent")
    {
      foreach ($node in $nodeList)
      {
        # there are some nodes that match xpath, delete without comparing them to fragment
        $removedNode = $node.get_ParentNode().RemoveChild($node)
        $XPathsDeleted += $setting.xpath
        $module.Debug($removedNode.get_OuterXml() + " removed")
      }
    }
    else
    {
      # state -eq 'present'
      $xmlfragment = $null
      Try
      {
        $xmlfragment = [xml]$setting.fragment
      }
      Catch
      {
        $module.FailJson("Failed to parse fragment as XML: $($_.Exception.Message)")
      }

      foreach ($node in $nodeList)
      {
        $candidate = $xmlorig.CreateElement($xmlfragment.get_DocumentElement().get_Name(), $xmlorig.get_DocumentElement().get_NamespaceURI())
        Copy-Xml -dest $candidate -src $xmlfragment.DocumentElement -xmlorig $xmlorig

        if ($node.get_NodeType() -eq "Document")
        {
          $node = $node.get_DocumentElement()
        }
        if ($node.ChildNodes.Count -eq 0)
        {
          $elements = @($node)
        }
        else
        {
          $elements = $node.get_ChildNodes()
        }
        [bool]$present = $false
        $element_count = $elements.get_Count()
        $nstatus = "node: " + $node.get_Value() + " element: " + $elements.get_OuterXml() + " Element count is $element_count"
        $module.Warn($nstatus)
        if ($elements.get_Count())
        {
          if (($module.Verbosity -gt 2) -or $module.DebugMode)
          {
            $err = @()
            $module.Result.err = { $err }.Invoke()
          }
          foreach ($element in $elements)
          {
            $estatus = "element is " + $element.get_OuterXml()
            $module.Warn($estatus)
            try
            {
              Compare-XmlDocs $candidate $element
              $present = $true
              break
            }
            catch
            {
              if (($module.Verbosity -gt 2) -or $module.DebugMode)
              {
                $module.Result.err.Add($_.Exception.ToString())
              }
            }
          }
          if (-Not $present -and ($setting.state -eq "present"))
          {
            [void]$node.AppendChild($candidate)
            $XPathsUpdated += $setting.xpath
          }
        }
      }
    }
  }
  elseif ($setting.type -eq "text")
  {
    foreach ($node in $nodeList)
    {
      if ($node.get_InnerText() -ne $setting.fragment)
      {
        $node.set_InnerText($setting.fragment)
        $XPathsUpdated += $setting.xpath
      }
    }
  }
  elseif ($setting.type -eq "attribute")
  {
    foreach ($node in $nodeList)
    {
      if ($setting.state -eq 'present')
      {
        if ($node.NodeType -eq 'Attribute')
        {
          if ($node.Name -eq $setting.attribute -and $node.Value -ne $setting.fragment )
          {
            # this is already the attribute with the right name, so just set its value to match fragment
            $node.Value = $setting.fragment
            $XPathsUpdated += $setting.xpath + "/@" + $setting.attribute
          }
        }
        else
        {
          # assume NodeType is Element
          if (!$node.HasAttribute($setting.attribute) -or ($node.($setting.attribute) -ne $setting.fragment))
          {
            if (!$node.HasAttribute($setting.attribute))
            {
              # add attribute to Element if missing
              $node.SetAttributeNode($setting.attribute, $xmlorig.get_DocumentElement().get_NamespaceURI())
            }
            #set the attribute into the element
            $node.SetAttribute($setting.attribute, $setting.fragment)
            $XPathsUpdated += $setting.xpath + "/@" + $setting.attribute
          }
        }
      }
      elseif ($setting.state -eq 'absent')
      {
        if ($node.NodeType -eq 'Attribute')
        {
          $attrNode = [System.Xml.XmlAttribute]$node
          $parent = $attrNode.OwnerElement
          $parent.RemoveAttribute($setting.attribute)
          $XPathsDeleted += $setting.xpath
        }
        else
        {
          # element node processing
          if ($node.Name -eq $setting.attribute )
          {
            # note not caring about the state of 'fragment' at this point
            $node.RemoveAttribute($setting.attribute)
            $XPathsDeleted += $setting.xpath
          }
        }
      }
      else
      {
        $module.Warn("Unexpected state when processing attribute $($setting.attribute), add was $add, state was $($setting.state)")
      }
    }
  }
}

if (($XPathsUpdated.Length -eq 0) -and ($XPathsDeleted.Length -eq 0))
{
  $module.Result.changed = $false
  $module.Result.msg = "All settings are up-to-date."
}
else
{
  if (-not $module.CheckMode)
  {
    Save-ChangedXml -xmlorig $xmlorig -result $module.Result -message "" -check_mode $module.CheckMode -backup $backup
  }
  $module.Result.changed = $true
  $module.Result.msg = "" + $XPathsUpdated.Length + " settings updated, " + $XPathsDeleted.Length + " settings deleted"
  $module.Result.settingsupdated = $XPathsUpdated
  $module.Result.settingsdeleted = $XPathsDeleted
}

$module.ExitJson()
