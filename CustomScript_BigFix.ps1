﻿workflow install-Bigfix-agent
{
    Param
    (
        [Parameter(mandatory=$true)]
        [boolean] $DryRun
    )

    $Conn = Get-AutomationConnection -Name AzureRunAsConnection
    Add-AzureRMAccount -ServicePrincipal -Tenant $Conn.TenantID -ApplicationId $Conn.ApplicationID -CertificateThumbprint $Conn.CertificateThumbprint
    Select-AzureRmSubscription -SubscriptionId $Conn.SubscriptionID

    if ($DryRun -eq $true)
    {
        Write-Output("This script was executed in Dry Run mode.  Bigfix Extension will not be installed.")
    }

    $ResourceGroupList = Get-AzureRmResourceGroup -Verbose
    ForEach ($ResourceGroupName in $ResourceGroupList.ResourceGroupName)
    {
        InlineScript 
        {
            $ResourceGroupName = $Using:ResourceGroupName
            $Settings = $Using:Settings
            $ProtectedSettings = $Using:ProtectedSettings

            $DryRun = $Using:DryRun

            $BigfixNewInstallCount = 0

            $VMList = Get-AzureRmVM -ResourceGroupName $ResourceGroupName -WarningAction SilentlyContinue -Verbose

            ForEach ($VM in $VMList)
            {
                $IsVMExtensionInstalled = Get-AzureRmVMExtension `
                                                -ResourceGroupName $ResourceGroupName `
                                                -VMName $VM.Name `
                                                -Name CustomBigfix `
                                                -ErrorAction SilentlyContinue `
                                                -WarningAction SilentlyContinue

                if ($IsVMExtensionInstalled -eq $null)
                {
                    
                   
                    
                    $VMPowerState = $VM | Get-AzureRmVM -Status -WarningAction SilentlyContinue | Select -ExpandProperty Statuses | ?{ $_.Code -match "PowerState" } | Select -ExpandProperty DisplayStatus

                    if ($VMPowerState -eq "VM running")
                    {
                        if ($VM.StorageProfile.OsDisk.OsType -eq "Windows")
                        {

                        $agentState = $VM | Select -ExpandProperty OSProfile | Select -ExpandProperty Windowsconfiguration | Select ProvisionVMAgent

                        if ($agentState -eq "True")
                        {
                            Write-Output("Agent on $VM is running and healthy")

                            if ($DryRun -eq $false)
                            {
                                Write-Output("Installing Bigfix agent on Windows Server: " + $ResourceGroupName + " / " + $VM.Name)

                                Set-AzureRmVMCustomScriptExtension `
                                                        -ResourceGroupName $ResourceGroupName `
                                                        -VMName $VM.name `
                                                        -FileName 'BigFix.ps1' `
                                                        -Run 'BigFix.ps1' `
                                                        -Location 'East US' `
                                                        -Name CustomBigfix `
                                                        -StorageAccountName dgc01dscforlinux `
                                                        -StorageAccountKey nzzeXSnWWDQGwCex0ARgZDwvdQQSISB0gseare/wJ0Hd2rGyB8bpR0ulWptCB+2bwXjUelVGhTUHabDd9iz6Ow== `
                                                        -ContainerName customscripts
                               
                            }

                            $BigfixNewInstallCount++
                        }
                    }

                        else
                        {
                            if ($DryRun -eq $false)
                            {
                                Write-Output("Linux Server: " + $ResourceGroupName + " / " + $VM.Name)

                                }
                            
                            $BigfixNewInstallCount++
                        }
                    }
                   
                }
            }

            if ($BigfixNewInstallCount -gt 0)
            {
                if ($DryRun -eq $true)
                {
                    Write-Output("Status for " + $ResourceGroupName + ": Bigfix Extension needed on " + $BigfixNewInstallCount + " VM(s)")
                }
                else
                {
                    Write-Output("Status for " + $ResourceGroupName + ": Bigfix Extension installed on " + $BigfixNewInstallCount + " VM(s)")
                }
            }
            else
            {
                Write-Output("Status for " + $ResourceGroupName + ": No changes")
            }
        }
    }

    Write-Output("Finished checking VMs")
}