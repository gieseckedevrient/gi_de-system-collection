#!powershell

# Copyright: (c) 2021, Giesecke Devrient

#AnsibleRequires -CSharpUtil Ansible.Basic

# TODO : handle switch in useraccount change when running as a service

$spec = @{
    options             = @{
        name                                     = @{ type = 'str'; required = $true }
        identity_username                        = @{ type = 'str'; required = $true }
        identity_password                        = @{ type = 'str'; default = '' ; no_log = $true }
        security_accesschecklevel                = @{ type = 'int'; default = 1; choices = 0, 1 } # COMAdminAccessChecksApplicationLevel = 0, COMAdminAccessChecksApplicationComponentLevel = 1
        security_applicationaccesschecksenforced = @{ type = 'bool'; default = $false }
        security_impersonationlevel              = @{ type = 'int'; default = 3; choices = 1, 2, 3, 4 } #COMAdminImpersonationAnonymous= 1, COMAdminImpersonationIdentify = 2, COMAdminImpersonationImpersonate =3, COMAdminImpersonationDelegate = 4
        activation_applicationrootdirectory      = @{ type = 'str'; default = '' ; required = $false }
        components                               = @{
            type     = 'list'
            elements = 'dict'
            options  = @{
                name                             = @{ type = 'str'; required = $true }
                transactions_transactionsupport  = @{ type = 'int'; choices = 0, 1, 2, 3, 4; default = 1 } #Transaction COMAdminTransactionIgnored (0)COMAdminTransactionNone (1)COMAdminTransactionSupported (2)COMAdminTransactionRequired (3)COMAdminTransactionRequiresNew (4)
                activation_activationcontext     = @{ type = 'str'; default = 'Default' ; choices = 'Default', 'Client', 'NoForce' }
                concurrency_synchronization      = @{ type = 'int'; default = 3 ; choices = 0, 1, 2, 3, 4 } #COMAdminSynchronizationIgnored  =0,COMAdminSynchronizationNone =1, COMAdminSynchronizationSupported =2, COMAdminSynchronizationRequired = 3, COMAdminSynchronizationRequiresNew = 4
                activation_noforce_supportevents = @{ type = 'bool'; default = $true } # EventTrackingEnabled
                activation_noforce_enablejit     = @{ type = 'bool'; default = $false } # JustInTimeActivation
            }
        }
    }
    supports_check_mode = $false
}
$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$Name = $module.Params.name
$UserName = $module.Params.identity_username
$Password = $module.Params.identity_password
$AccessCheckLevel = $module.Params.security_accesschecklevel
$ApplicationAccessChecksEnabled = $module.Params.security_applicationaccesschecksenforced
$ImpersonationLevel = $module.Params.security_impersonationlevel
$ApplicationDirectory = $module.Params.activation_applicationrootdirectory
$ComponentsCollection = $module.Params.components

function Test-UserNameIsManagedServiceAccount
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $UserName
    )
    if ($UserName.Substring($UserName.Length - 1, 1) -eq '$')
    {
        if ($UserName.Substring(0, 12) -ne 'nt authority')
        {
            return $true
        }
    }
    return $false
}


$module.Result.changed = $false
$module.Result.msg = @{
    components  = @{
        msg       = ''
        component = @{}
    }
    application = @{
        msg    = ''
        checks = @{}
    }
}
try
{
    # Get the collection
    $comAdmin = New-Object -ComObject COMAdmin.COMAdminCatalog


    $apps = $comAdmin.GetCollection('Applications')
    $apps.Populate()

    # Fetch the application
    $app = $apps | Where-Object { $_.Name -eq $Name }

    # Fail if application not existing (module not meant for that yet) see more advanced way to : https://serverfault.com/a/817177
    if (-not ($app))
    {
        $module.FailJson("Application not installed : $($Name). Install it first before adjusting its parameters")
    }
    $serviceCreationNeeded = $false
    $changesApplied = $false
    # Check if managed service account
    $workingWithManagedServiceAccount = Test-UserNameIsManagedServiceAccount -Username $UserName

    if ($workingWithManagedServiceAccount)
    {
        # ServiceName is null if not configured to run as a service, see https://docs.microsoft.com/en-us/windows/win32/cossdk/applications#servicename
        $serviceCreationNeeded = ($app.Value('ServiceName') -eq '')

        if ($serviceCreationNeeded)
        {
            $module.Result.msg.application.checks.Add('Service', 'Service creation needed')
            try
            {
                $module.Debug('Creating a service for "{0}"' -f $Name )

                #comAdmin.StartApplication($Name)
                $comAdmin.CreateServiceForApplication($Name, $Name, 'SERVICE_AUTO_START', 'SERVICE_ERROR_CRITICAL', '', $UserName, '', $False)
                $comAdmin.ShutdownApplication($Name)
                $changesApplied = $true
                $module.Result.changed = $true
                $module.Result.msg.application.msg += 'Service Created'
            }
            catch
            {
                $module.FailJson("Error while creating service for application $($Name)", $_)
            }
        }

    }
    else
    {
        # not a managed service account

        $serviceRemovalNeeded = ($app.Value('ServiceName') -ne '')
        if ($serviceRemovalNeeded)
        {
            $module.Result.msg.application.checks.Add('Service', 'Service removal needed')
            try
            {
                $module.Debug('Removing the NT service for "{0}"' -f $Name )
                try
                {
                    $comAdmin.ShutdownApplication($Name)
                }
                catch {}
                $comAdmin.DeleteServiceForApplication($Name)
                $changesApplied = $true
                $module.Result.changed = $true
                $module.Result.msg.application.msg += "Service removed `n"
            }
            catch
            {
                $module.FailJson("Error while removing NT service for application $($Name): $($_.Exception.Message)")
            }
        }
    }

    if ($changesApplied)
    {
        # reload the collection
        $apps = $comAdmin.GetCollection('Applications')
        $apps.Populate()
        # Fetch (again) the application
        $app = $apps | Where-Object { $_.Name -eq $Name }
    }


    # Compare the settings provided
    $changeNeeded = $false
    if ($app.Value('Identity') -ne $UserName)
    {
        $module.Result.msg.application.checks.Add('Identity', "Change required from $($app.Value('Identity')) to $($UserName)")
        $changeNeeded = $true
    }
    if ($app.Value('AccessChecksLevel') -ne $AccessCheckLevel)
    {
        $module.Result.msg.application.checks.Add('AccessChecksLevel', "Change required from $($app.Value('AccessChecksLevel')) to $($AccessCheckLevel)")
        $changeNeeded = $true
    }
    if ($app.Value('ApplicationAccessChecksEnabled') -ne $ApplicationAccessChecksEnabled)
    {
        $module.Result.msg.application.checks.Add('ApplicationAccessChecksEnabled', "Change required from $($app.Value('ApplicationAccessChecksEnabled')) to $($ApplicationAccessChecksEnabled)")
        $changeNeeded = $true
    }
    if ($app.Value('ImpersonationLevel') -ne $ImpersonationLevel)
    {
        $module.Result.msg.application.checks.Add('ImpersonationLevel', "Change required from $($app.Value('ImpersonationLevel')) to $($ImpersonationLevel)")
        $changeNeeded = $true
    }
    if ($null -ne $ApplicationDirectory)
    {
        if ($app.Value('ApplicationDirectory') -ne $ApplicationDirectory)
        {
            $module.Result.msg.application.checks.Add('ApplicationDirectory', "Change required from $($app.Value('ApplicationDirectory')) to $($ApplicationDirectory)")
            $changeNeeded = $true
        }
    }

    # check the components settings
    $changeNeededOnOneComponent = $false
    $components = $apps.GetCollection('Components', $app.Value('ID'))
    $components.Populate()
    Foreach ($TargetedComponent in $ComponentsCollection)
    {

        $component = $components | Where-Object { $_.Name -eq $TargetedComponent.name }
        if (-not ($component))
        {
            $module.FailJson("Component not found : $($TargetedComponent.name)")
        }
        $resultComponent = @{
            checks = @{}
            msg    = ''
        }
        # TODO: support wildcar for component settings

        if ($component.Value('Transaction') -ne $TargetedComponent.transactions_transactionsupport)
        {
            $resultComponent.checks.Add('Transaction', "Change required from $($component.Value('Transaction')) to $($TargetedComponent.transactions_transactionsupport)")
            $changeNeededOnOneComponent = $true
        }
        if ($component.Value('Synchronization') -ne $TargetedComponent.concurrency_synchronization)
        {
            $resultComponent.checks.Add('Synchronization', "Change required from $($component.Value('Synchronization')) to $($TargetedComponent.concurrency_synchronization)")
            $changeNeededOnOneComponent = $true
        }
        switch ( $TargetedComponent.activation_activationcontext )
        {
            Client
            {
                if ($component.Value('MustRunInClientContext') -ne $true)
                {
                    $resultComponent.checks.Add('Activation', "Client context. Change required from $($component.Value('MustRunInClientContext')) to $($false)")
                    $changeNeededOnOneComponent = $true
                }
                if ($component.Value('MustRunInDefaultContext') -ne $false)
                {
                    $resultComponent.checks.Add('MustRunInDefaultContext', "Client context. Change required from $($component.Value('MustRunInDefaultContext')) to $($true)")
                    $changeNeededOnOneComponent = $true
                }
            }
            NoForce
            {
                if ($component.Value('MustRunInClientContext') -ne $false)
                {
                    $resultComponent.checks.Add('MustRunInClientContext', "NoForce context. Change required from  $($component.Value('MustRunInClientContext')) to $($true)")
                    $changeNeededOnOneComponent = $true
                }
                if ($component.Value('MustRunInDefaultContext') -ne $false)
                {
                    $resultComponent.checks.Add('MustRunInDefaultContext', "NoForce context. Change required from $($component.Value('MustRunInDefaultContext')) to $($true)")
                    $changeNeededOnOneComponent = $true
                }
                if ($component.Value('EventTrackingEnabled') -ne $TargetedComponent.activation_noforce_supportevents)
                {
                    $resultComponent.checks.Add('EventTrackingEnabled', "NoForce context. Change required from $($component.Value('EventTrackingEnabled')) to $($TargetedComponent.activation_noforce_supportevents)")
                    $changeNeededOnOneComponent = $true
                }
                if ($component.Value('JustInTimeActivation') -ne $TargetedComponent.activation_noforce_enablejit)
                {
                    $resultComponent.checks.Add('JustInTimeActivation', "NoForce context. Change required from $($component.Value('JustInTimeActivation')) to $($TargetedComponent.activation_noforce_enablejit)")
                    $changeNeededOnOneComponent = $true
                }
                if ($TargetedComponent.enablejit -and ($TargetedComponent.concurrency_synchronization -lt 3))
                {
                    $module.FailJson('Call mismatch, enablejit enable must have synchronization set to 3 or 4')
                }
            }
            Default
            {
                if ($component.Value('MustRunInClientContext') -ne $false)
                {
                    $resultComponent.checks.Add('MustRunInClientContext', "Default context. Change required from $($component.Value('MustRunInClientContext')) to $($true)")
                    $changeNeededOnOneComponent = $true
                }
                if ($component.Value('MustRunInDefaultContext') -ne $true)
                {
                    $resultComponent.checks.Add('MustRunInDefaultContext', "Default context. Change required from $($component.Value('MustRunInDefaultContext')) to $($false)")
                    $changeNeededOnOneComponent = $true
                }
            }
        }
        $module.Result.msg.components.component.Add($TargetedComponent.name, $resultComponent) | Out-Null
    }



    # Make the application changes if needed
    if ($changeNeeded -eq $true)
    {
        # Set application properties
        if (-not $workingWithManagedServiceAccount)
        {
            $app.Value('Identity') = $UserName
            $app.Value('Password') = $Password
        }

        $app.Value('AccessChecksLevel') = $AccessCheckLevel
        $app.Value('ApplicationAccessChecksEnabled') = $ApplicationAccessChecksEnabled
        $app.Value('ImpersonationLevel') = $ImpersonationLevel
        if ($null -ne $ApplicationDirectory)
        {
            $app.Value('ApplicationDirectory') = $ApplicationDirectory
        }
        # Save collection
        $result = $apps.SaveChanges()
        if (-not $result -eq 1)
        {
            $module.FailJson("Error while SaveChanges. Return code : $($result)")
        }
        $module.Result.changed = $true
        $module.Result.msg.application.msg += 'Changes applied to application'
    }
    else
    {
        $module.Result.msg.application.msg += 'No change needed on the application'
    }
    # Handle the component settings changes

    if ($changeNeededOnOneComponent)
    {
        $failMessage = ''
        $failStatus = $false


        $components = $apps.GetCollection('Components', $app.Value('ID'))
        $components.Populate()
        Foreach ($TargetedComponent in $ComponentsCollection)
        {
            $component = $components | Where-Object { $_.Name -eq $TargetedComponent.name }
            # we already know it exists
            $component.Value('Transaction') = $TargetedComponent.transactions_transactionsupport
            $component.Value('Synchronization') = $TargetedComponent.concurrency_synchronization
            $component.Value('EventTrackingEnabled') = $TargetedComponent.activation_noforce_supportevents
            switch ( $TargetedComponent.activation_activationcontext )
            {
                Client
                {
                    $component.Value('MustRunInClientContext') = $true
                    $component.Value('MustRunInDefaultContext') = $false
                }
                NoForce
                {
                    $component.Value('MustRunInClientContext') = $false
                    $component.Value('MustRunInDefaultContext') = $false
                    $component.Value('EventTrackingEnabled') = $TargetedComponent.activation_noforce_supportevents
                    $component.Value('JustInTimeActivation') = $TargetedComponent.activation_noforce_enablejit
                }
                Default
                {
                    $component.Value('MustRunInClientContext') = $false
                    $component.Value('MustRunInDefaultContext') = $true
                }
            }

            $resultcomp = $components.SaveChanges()
            if (-not $resultcomp -eq 1)
            {
                $failMessage += "Error while SaveChanges for Componenet $($TargetedComponent.name) Return code : $($resultcomp)"
                $module.Result.msg.components.component[$TargetedComponent.name].msg += $failMessage
                $failStatus = $true
            }
            $module.Result.msg.components.component[$TargetedComponent.name].msg += "Changes applied to component $($TargetedComponent.name) `n"
            $module.Result.changed = $true
        }

        if ($failStatus)
        {
            $module.FailJson($failMessage)
        }
    }
    else
    {
        $module.Result.msg.components.msg += "No change needed on components `r`n"
    }
}
catch
{
    $module.FailJson("Overall Failure`n. Note this module needs administrator priviledges", $_)
}
$module.ExitJson()
