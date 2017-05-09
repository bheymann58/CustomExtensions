$resourceGroupName = 'DH-AZR-C01-GLB-IN-001'
$vmname = 'HeymannExt01'

Set-AzureRmVMCustBigfixcriptExtension -ResourceGroupName $resourceGroupName -VMName $vmname -FileName 'BigFix.ps1' -Run 'BigFix.ps1' -Location 'East US' -Name CustomBigfix -StorageAccountName dgc01dscforlinux -StorageAccountKey nzzeXSnWWDQGwCex0ARgZDwvdQQSISB0gseare/wJ0Hd2rGyB8bpR0ulWptCB+2bwXjUelVGhTUHabDd9iz6Ow== -ContainerName custBigfixcripts

Update-AzureRmVM -ResourceGroupName $vmname -VM $resourceGroupName