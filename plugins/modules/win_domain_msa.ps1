#!powershell

# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ActiveDirectory

$spec = @{
    options             = @{
        state                                      = @{ type = 'str'; required = $false ; default = "present" ; choices = "present", "absent", "query" }
        attributes                                  = @{ type = 'list'; required = $false}
        groups_action                              = @{ type = 'str'; required = $false ; default = "replace" ; choices = "add", "remove", "replace" }
        domain_accountname                         = @{ type = 'str'; required = $false }
        domain_password                            = @{ type = 'str'; required = $false ; no_log = $true }
        domain_server                              = @{ type = 'str'; required = $false }
        dnshostname                                = @{ type = 'str'; required = $false }
        name                                       = @{ type = 'str'; required = $true }

        restricttooutboundauthenticationonly       = @{ type = 'bool'; required = $false ; default = $false }
        restricttosinglecomputer                   = @{ type = 'bool'; required = $false ; default = $false }
        description                                = @{ type = 'str'; required = $false}
        groups                                     = @{
            type     = 'list'
            elements = 'dict'
            required = $false
            # options  = @{
            #     name = @{ type = 'str'; required = $true }
            # }
        }
        enabled                                    = @{ type = 'bool'; required = $false ; default = $true }
        path                                       = @{ type = 'str'; required = $false }
        principalsallowedtodelegatetoaccount       = @{ type = 'str'; required = $false }
        principalsallowedtoretrievemanagedpassword = @{ type = 'str'; required = $false }
    }
    required_together   = @(, @("domain_accountname", "domain_password")) # if providing specific domain credentials
    required_if         = @(
        , @("restricttosinglecomputer", $false, @("principalsallowedtoretrievemanagedpassword")) # principal needed if not dedicated to single computer
    )
    required_one_of     = @(
        , @('dnshostname', 'restricttooutboundauthenticationonly', 'restricttosinglecomputer')
    )
    supports_check_mode = $true
}
$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$module.Result.changed = $false


$ErrorActionPreference = "Stop"


$check_mode = $module.CheckMode
# Module control parameters
$state = $module.Params.state
$groups_action = $module.Params.groups_action
$domain_accountname = $module.Params.domain_accountname
$domain_password = $module.Params.domain_password
$domain_server = $module.Params.domain_server
$dnshostname = $module.Params.dnshostname
$accountname = $module.Params.name
$restricttooutboundauthenticationonly = $module.Params.restricttooutboundauthenticationonly
$restricttosinglecomputer = $module.Params.restricttosinglecomputer
$description = $module.Params.description
$groups = $module.Params.groups
$enabled = $module.Params.enabled
$path = $module.Params.path
$principalsallowedtodelegatetoaccount = $module.Params.principalsallowedtodelegatetoaccount
$principalsallowedtoretrievemanagedpassword = $module.Params.principalsallowedtoretrievemanagedpassword

$attributes = $module.Params.attributes

try
{
    if ($null -eq (Get-Module "ActiveDirectory" -ErrorAction SilentlyContinue))
    {
        Import-Module ActiveDirectory
    }
}
catch
{
    $module.FailJson("Failed to import ActiveDirectory PowerShell module. This module should be run on a domain controller, and the ActiveDirectory module must be available.: $($_.Exception.Message)", $_)
}

$extra_args = @{}
if ($null -ne $domain_accountname)
{
    $domain_password = ConvertTo-SecureString $domain_password -AsPlainText -Force
    $credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $domain_accountname, $domain_password
    $extra_args.Credential = $credential
}
if ($null -ne $domain_server)
{
    $extra_args.Server = $domain_server
}

$create_args = @{}
if ($null -ne $dnshostname)
{
    $create_args.DNSHostName = $dnshostname
}
if ($restricttooutboundauthenticationonly)
{
    $create_args.RestrictToOutboundAuthenticationOnly = $restricttooutboundauthenticationonly
}
if ($restricttosinglecomputer)
{
    $create_args.RestrictToSingleComputer = $restricttosinglecomputer
}

try
{
    $account_obj = Get-ADServiceAccount -Identity $accountname -Properties * @extra_args
}
catch
{
    $account_obj = $null
}
if (($null -ne $principalsallowedtoretrievemanagedpassword) -and !($restricttosinglecomputer)) {
    try
    {
        $adprincipalsallowedtoretrievemanagedpassword = Get-ADGroup $principalsallowedtoretrievemanagedpassword
    }
    catch
    {
        $module.FailJson("Group '$principalsallowedtoretrievemanagedpassword' is not a valid Directory Object for var 'principalsallowedtoretrievemanagedpassword'. Ensure it exists with call to 'community.windows.win_domain_group': $($_.Exception.Message)", $_)
    }
}

If ($state -eq 'present')
{
    # Ensure user exists
    try
    {

        # If the account does not exist, create it
        If (-not $account_obj)
        {
            If ($null -ne $path)
            {
                New-ADServiceAccount @create_args -Name $accountname -Path $path -WhatIf:$check_mode @extra_args
                Start-Sleep -Seconds 120
            }
            Else
            {
                New-ADServiceAccount @create_args -Name $accountname -WhatIf:$check_mode @extra_args
                Start-Sleep -Seconds 120
            }
            $module.Result.changed = $true
            If ($check_mode)
            {
                $module.ExitJson()
            }
            $account_obj = Get-ADServiceAccount -Identity $accountname -Properties * @extra_args
        }

        # Assign other account settings
        If (($null -ne $principalsallowedtodelegatetoaccount) -and ($principalsallowedtodelegatetoaccount -ne $account_obj.PrincipalsAllowedToDelegateToAccount))
        {
            Set-ADServiceAccount -Identity $accountname -PrincipalsAllowedToDelegateToAccount $principalsallowedtodelegatetoaccount -WhatIf:$check_mode @extra_args
            $account_obj = Get-ADServiceAccount -Identity $accountname -Properties * @extra_args
            $module.Result.changed = $true
        }
        If (($null -ne $principalsallowedtoretrievemanagedpassword) -and ($adprincipalsallowedtoretrievemanagedpassword -notin $account_obj.PrincipalsAllowedToRetrieveManagedPassword))
        {
            $existingAdPrincipal = $account_obj.PrincipalsAllowedToRetrieveManagedPassword
            $newAdPrincipals = ($existingAdPrincipal += $adprincipalsallowedtoretrievemanagedpassword.DistinguishedName)
            Set-ADServiceAccount -Identity $accountname -PrincipalsAllowedToRetrieveManagedPassword $newAdPrincipals -WhatIf:$check_mode @extra_args
            $account_obj = Get-ADServiceAccount -Identity $accountname -Properties * @extra_args
            $module.Result.changed = $true
        }
        If (($null -ne $description) -and ($description -ne $account_obj.Description))
        {
            Set-ADServiceAccount -Identity $accountname -description $description -WhatIf:$check_mode @extra_args
            $account_obj = Get-ADServiceAccount -Identity $accountname -Properties * @extra_args
            $module.Result.changed = $true
        }
        If ($enabled -ne $account_obj.Enabled)
        {
            Set-ADServiceAccount -Identity $accountname -Enabled $enabled -WhatIf:$check_mode @extra_args
            $account_obj = Get-ADServiceAccount -Identity $accountname -Properties * @extra_args
            $module.Result.changed = $true
        }

        # Set additional attributes
        $set_args = $extra_args.Clone()
        $run_change = $false
        if ($null -ne $attributes)
        {
            $add_attributes = @{}
            $replace_attributes = @{}
            foreach ($attribute in $attributes.GetEnumerator())
            {
                $attribute_name = $attribute.Name
                $attribute_value = $attribute.Value

                $valid_property = [bool]($account_obj.PSobject.Properties.name -eq $attribute_name)
                if ($valid_property)
                {
                    $existing_value = $account_obj.$attribute_name
                    if ($existing_value -cne $attribute_value)
                    {
                        $replace_attributes.$attribute_name = $attribute_value
                    }
                }
                else
                {
                    $add_attributes.$attribute_name = $attribute_value
                }
            }
            if ($add_attributes.Count -gt 0)
            {
                $set_args.Add = $add_attributes
                $run_change = $true
            }
            if ($replace_attributes.Count -gt 0)
            {
                $set_args.Replace = $replace_attributes
                $run_change = $true
            }
        }

        if ($run_change)
        {
            try
            {
                $account_obj = $account_obj | Set-ADServiceAccount -WhatIf:$check_mode -PassThru @set_args
            }
            catch
            {
                $module.FailJson("Failed to change account '$($accountname)': $($_.Exception.Message)", $_)
            }
            $module.Result.changed = $true
        }

        # Configure group assignment
        If ($null -ne $groups)
        {
            $group_list = $groups

            $groups = @()
            Foreach ($group in $group_list)
            {
                $groups += (Get-ADGroup -Identity $group @extra_args).DistinguishedName
            }

            $assigned_groups = @()
            Foreach ($group in (Get-ADServiceAccount -Identity $accountname -Properties * @extra_args | Get-ADPrincipalGroupMembership @extra_args))
            {
                $assigned_groups += $group.DistinguishedName
            }

            switch ($groups_action)
            {
                "add"
                {
                    Foreach ($group in $groups)
                    {
                        If (-not ($assigned_groups -Contains $group))
                        {
                            Add-ADGroupMember -Identity $group -Members $accountname -WhatIf:$check_mode @extra_args
                            $account_obj = Get-ADServiceAccount -Identity $accountname -Properties * @extra_args
                            $module.Result.changed = $true
                        }
                    }
                }
                "remove"
                {
                    Foreach ($group in $groups)
                    {
                        If ($assigned_groups -Contains $group)
                        {
                            Remove-ADGroupMember -Identity $group -Members $accountname -Confirm:$false -WhatIf:$check_mode @extra_args
                            $account_obj = Get-ADServiceAccount -Identity $accountname -Properties * @extra_args
                            $module.Result.changed = $true
                        }
                    }
                }
                "replace"
                {
                    Foreach ($group in $assigned_groups)
                    {
                        If (($group -ne $account_obj.PrimaryGroup) -and -not ($groups -Contains $group))
                        {
                            Remove-ADGroupMember -Identity $group -Members $accountname -Confirm:$false -WhatIf:$check_mode @extra_args
                            $account_obj = Get-ADServiceAccount -Identity $accountname -Properties * @extra_args
                            $module.Result.changed = $true
                        }
                    }
                    Foreach ($group in $groups)
                    {
                        If (-not ($assigned_groups -Contains $group))
                        {
                            Add-ADGroupMember -Identity $group -Members $accountname -WhatIf:$check_mode @extra_args
                            $account_obj = Get-ADServiceAccount -Identity $accountname -Properties * @extra_args
                            $module.Result.changed = $true
                        }
                    }
                }
            }
        }

    }
    catch
    {
        $module.FailJson("Overall failure state '$state': $($_.Exception.Message)", $_)
    }
}
ElseIf ($state -eq 'absent')
{
    # Ensure user does not exist
    try
    {
        If ($account_obj)
        {
            Remove-ADServiceAccount $account_obj -Confirm:$false -WhatIf:$check_mode @extra_args
            $module.Result.changed = $true
            If ($check_mode)
            {
                $module.ExitJson()
            }
            $account_obj = $null
        }
    }
    catch
    {
        $module.FailJson("Overall failure state '$state': $($_.Exception.Message)", $_)
    }
}

try
{
    If ($account_obj)
    {
        $account_obj = Get-ADServiceAccount -Identity $accountname -Properties * @extra_args
        $module.Result.name = $account_obj.Name
        $module.Result.enabled = $account_obj.Enabled
        $module.Result.distinguished_name = $account_obj.DistinguishedName
        $module.Result.description = $account_obj.Description
        $module.Result.account_locked = $account_obj.LockedOut
        $module.Result.sid = [string]$account_obj.SID
        $module.Result.upn = $account_obj.UserPrincipalName
        $account_groups = @()
        Foreach ($group in (Get-ADServiceAccount -Identity $accountname -Properties * @extra_args | Get-ADPrincipalGroupMembership @extra_args))
        {
            $account_groups += $group.name
        }
        $module.Result.groups = $account_groups
        $module.Result.msg = "User '$accountname' is present"
        $module.Result.state = "present"
    }
    Else
    {
        $module.Result.name = $accountname
        $module.Result.msg = "User '$accountname' is absent"
        $module.Result.state = "absent"
    }
}
catch
{
    $module.FailJson("Overall failure fetching Result: $($_.Exception.Message)", $_)
}

$module.ExitJson()
