# Create a Windows VM

# Variables for common values
$resource_name = "Ansible"
$resource_location = "South India"
$Network_AddressPrefix = "10.0.0.0/16"
$Subnet1_AddressPrefix = "10.0.0.0/24"
$Subnet2_AddressPrefix = "10.0.1.0/24"
$User_Name = "Nandhu"
$Password = "Marubhoomi@1"
$VM_Size = "Standard_B2s"
$OS_Publisher_Name = "MicrosoftWindowsServer"
$OS_Offer = "WindowsServer"
$OS_SKU = "2016-Datacenter"

#You can modify below variables as per request
$RG_Name = ($resource_name.ToLower()+"-RG")
$Vnet_Name = ($resource_name.ToLower()+"-Vnet")
$Subnet1_Name = ($resource_name.ToLower()+"-Vnet"+"-FrontSubnet")
$Subnet2_Name = ($resource_name.ToLower()+"-Vnet"+"-BackendSubnet")
$VM_Name = ($resource_name.ToLower()+"-VM")
$PublicIP_Name = ($resource_name.ToLower()+"-VM"+"-PIP")
$NSG_Name = ($resource_name.ToLower()+"-VM"+"-NSG")
$NIC_Name = ($resource_name.ToLower()+"-VM"+"-NIC")

# Create a resource group
New-AzResourceGroup -Name $RG_Name -Location $resource_location

# Create a Subnet1
$Subnet1Config = New-AzVirtualNetworkSubnetConfig -Name $Subnet1_Name -AddressPrefix $Subnet1_AddressPrefix

# Create a Subnet2
$Subnet2Config = New-AzVirtualNetworkSubnetConfig -Name $Subnet2_Name -AddressPrefix $Subnet2_AddressPrefix

# Create a virtual network & Associate the subnet to the virtual network
$Virtual_Network = New-AzVirtualNetwork -ResourceGroupName $RG_Name -Location $resource_location `
					-Name $Vnet_Name -AddressPrefix $Network_AddressPrefix -Subnet $Subnet1Config, $Subnet2Config

# Create a new public IP address
$PublicIP = New-AzPublicIpAddress -Name $PublicIP_Name -ResourceGroupName $RG_Name -Location $resource_location -AllocationMethod Static

# Create a Security Rules and assign to NSG
$nsg_rule1 = New-AzNetworkSecurityRuleConfig -Name rdp-rule -Description "Allow RDP" -Access Allow -Protocol Tcp -Direction Inbound -Priority 1000 `
			-SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389

$nsg_rule2 = New-AzNetworkSecurityRuleConfig -Name web-rule -Description "Allow HTTP" -Access Allow -Protocol Tcp -Direction Inbound -Priority 1001 `
			-SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 80

$NSG = New-AzNetworkSecurityGroup -ResourceGroupName $RG_Name -Location $resource_location -Name $NSG_Name -SecurityRules $nsg_rule1,$nsg_rule2

# Create a Network interface card and associate with public IP address and NSG
$NIC = New-AzNetworkInterface -Name $NIC_Name -ResourceGroupName $RG_Name -Location $resource_location -SubnetId $Virtual_Network.Subnets[0].Id -PublicIpAddressId $PublicIP.Id -NetworkSecurityGroupId $NSG.Id

# Create a Credential
#$Credential = Get-Credential -Message "Enter a username and password for the virtual machine."
$PWord = $Password | ConvertTo-SecureString -Force -AsPlainText 
$Credential = New-Object PSCredential ($User_Name, $PWord)

#Create Linux VM Configuration
#Set-AzVMOperatingSystem -Linux -ComputerName $vmName -Credential $cred |
#Set-AzVMSourceImage -PublisherName Canonical -Offer UbuntuServer -Skus 14.04.2-LTS -Version latest

# Create a Windows virtual machine configuration
$VM_Config = New-AzVMConfig -VMName $VM_Name -VMSize $VM_Size | `
			Set-AzVMOperatingSystem -Windows -ComputerName $VM_Name -Credential $Credential | `
			Set-AzVMSourceImage -PublisherName $OS_Publisher_Name -Offer $OS_Offer -Skus $OS_SKU -Version latest | `
			Add-AzVMNetworkInterface -Id $NIC.Id

# Create a virtual machine
New-AzVM -ResourceGroupName $RG_Name -Location $resource_location -VM $VM_Config

