<#
    Microsoft Entra ID Lab Automation - West Europe
    - Creates users: Engineer1, Engineer2
    - Creates group: lab engineers
    - Adds users to group
    - Creates VM in rg-104, West Europe
      * Windows Server 2025 Datacenter (x64)
      * Size: Standard_D2ads_v6
      * Availability zone: 1
      * Spot instance: Enabled
    - Assigns 'Virtual Machine Contributor' on resource group 'rg-104' to the group
#>

# -------------------------
# 1. Parameters / settings
# -------------------------

$Location      = "westeurope"
$ResourceGroup = "rg-104"

# Entra ID domain
$domain = "clintonhycinthhotmail.onmicrosoft.com"

# Users as in the lab
$labUsers = @(
    @{
        UserName    = "Engineer1"
        DisplayName = "Engineer1"
        JobTitle    = "Lab Engineer"
    },
    @{
        UserName    = "Engineer2"
        DisplayName = "Engineer2"
        JobTitle    = "Lab Engineer"
    }
)

$aadGroupName = "lab engineers"

# VM details (matching manual lab)
$vmName           = "vm-lab"
$vmSize           = "Standard_D2ads_v6"
$vmZone           = 1
$vmImagePublisher = "MicrosoftWindowsServer"
$vmImageOffer     = "WindowsServer"
$vmImageSku       = "2025-datacenter"
$vmImageVersion   = "latest"

# Spot VM config
$priority         = "Spot"
$evictionPolicy   = "Deallocate"
$maxPrice         = -1

# -------------------------
# 2. Resource Group
# -------------------------

$rg = Get-AzResourceGroup -Name $ResourceGroup -ErrorAction SilentlyContinue
if (-not $rg) {
    New-AzResourceGroup -Name $ResourceGroup -Location $Location
}

# -------------------------
# 3. Entra ID: Users and Group
# -------------------------

$createdUsers = @()

foreach ($u in $labUsers) {
    $upn = "$($u.UserName)@$domain"

    $existingUser = Get-AzureADUser -All $true | Where-Object { $_.UserPrincipalName -eq $upn }
    if (-not $existingUser) {
        $passwordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
        $passwordProfile.Password = "Pass1234!!"

        $newUser = New-AzureADUser `
            -UserPrincipalName $upn `
            -DisplayName $u.DisplayName `
            -PasswordProfile $passwordProfile `
            -AccountEnabled $true `
            -MailNickname $u.UserName `
            -JobTitle $u.JobTitle

        $createdUsers += $newUser
    }
    else {
        $createdUsers += $existingUser
    }
}

# Create security group
$aadGroup = Get-AzureADGroup -All $true | Where-Object { $_.DisplayName -eq $aadGroupName } | Select-Object -First 1

if (-not $aadGroup) {
    $aadGroup = New-AzureADGroup `
        -DisplayName $aadGroupName `
        -MailEnabled $false `
        -SecurityEnabled $true `
        -MailNickname $aadGroupName.Replace(" ","")
}

# Add users to group
$groupMembers = Get-AzureADGroupMember -ObjectId $aadGroup.ObjectId -All $true | Select-Object -ExpandProperty ObjectId

foreach ($u in $createdUsers) {
    if ($groupMembers -notcontains $u.ObjectId) {
        Add-AzureADGroupMember -ObjectId $aadGroup.ObjectId -RefObjectId $u.ObjectId
    }
}

# -------------------------
# 4. Networking
# -------------------------

$vnetName   = "vnet-lab-weu-$((Get-Random -Minimum 1000 -Maximum 9999))"
$subnetName = "default"
$vnetPrefix = "10.0.0.0/16"
$subnetPrefix = "10.0.1.0/24"

$vnet = New-AzVirtualNetwork `
    -ResourceGroupName $ResourceGroup `
    -Location $Location `
    -Name $vnetName `
    -AddressPrefix $vnetPrefix `
    -Subnet @(
        New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix $subnetPrefix
    )

$publicIpName = "vm-lab-ip-weu-$((Get-Random -Minimum 1000 -Maximum 9999))"

$publicIP = New-AzPublicIpAddress `
    -Name $publicIpName `
    -ResourceGroupName $ResourceGroup `
    -Location $Location `
    -AllocationMethod Static `
    -Sku "Standard"

$nicName = "vm-lab-nic-weu-$((Get-Random -Minimum 1000 -Maximum 9999))"

$nic = New-AzNetworkInterface `
    -Name $nicName `
    -ResourceGroupName $ResourceGroup `
    -Location $Location `
    -SubnetId $vnet.Subnets[0].Id `
    -PublicIpAddressId $publicIP.Id

# -------------------------
# 5. VM creation (Spot + Zone 1 + 2025 Datacenter)
# -------------------------

$cred = Get-Credential -Message "Enter local admin credentials for the VM"

$vmConfig = New-AzVMConfig `
    -VMName $vmName `
    -VMSize $vmSize `
    -Priority $priority `
    -EvictionPolicy $evictionPolicy `
    -MaxPrice $maxPrice

$vmConfig.Zone = @("$vmZone")

$vmConfig = Set-AzVMOperatingSystem `
    -VM $vmConfig `
    -Windows `
    -ComputerName $vmName `
    -Credential $cred `
    -ProvisionVMAgent `
    -EnableAutoUpdate

$vmConfig = Set-AzVMSourceImage `
    -VM $vmConfig `
    -PublisherName $vmImagePublisher `
    -Offer $vmImageOffer `
    -Skus $vmImageSku `
    -Version $vmImageVersion

$vmConfig = Add-AzVMNetworkInterface -VM $vmConfig -Id $nic.Id

New-AzVM `
    -ResourceGroupName $ResourceGroup `
    -Location $Location `
    -VM $vmConfig `
    -Zone $vmZone

# -------------------------
# 6. RBAC assignment
# -------------------------

$roleName = "Virtual Machine Contributor"
$scope    = "/subscriptions/$((Get-AzContext).Subscription.Id)/resourceGroups/$ResourceGroup"

$role = Get-AzRoleDefinition -Name $roleName

$existingAssignment = Get-AzRoleAssignment -Scope $scope -ObjectId $aadGroup.ObjectId -ErrorAction SilentlyContinue

if (-not $existingAssignment) {
    New-AzRoleAssignment `
        -ObjectId $aadGroup.ObjectId `
        -RoleDefinitionId $role.Id `
        -Scope $scope | Out-Null
}

# -------------------------
# 7. Summary
# -------------------------

Write-Host "Lab setup completed."
Write-Host "Resource Group: $ResourceGroup"
Write-Host "Region: $Location"
Write-Host "VM Name: $vmName"
Write-Host "VM Size: $vmSize"
Write-Host "Availability Zone: $vmZone"
Write-Host "Image: $vmImageSku"
Write-Host "Users: $($labUsers.UserName -join ', ')"
Write-Host "Group: $aadGroupName"
Write-Host "RBAC: Virtual Machine Contributor assigned to group"
