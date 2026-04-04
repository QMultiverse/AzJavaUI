// infra/bicep/modules/jumpbox.bicep
// Creates the Jump Box VM — the only resource with a public IP.
// SSH is locked to your corporate IP via NSG.

param env string
param location string
param subnetId string
param corporateIpAddress string

@description('Admin username for the VM')
param adminUsername string = 'azureuser'

@allowed(['Basic', 'Standard', 'Premium'])
param sku string = 'Standard'

// Generate SSH key pair automatically
resource sshKey 'Microsoft.Compute/sshPublicKeys@2025-04-01' = {
  name: 'sshkey-jumpbox-${env}'
  location: location
  properties: {
    publicKey: 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCZYLDhlJotZDk1B21SORINApGsyakE+65bA2xqT+YttMj0zJpMe3Rl0gD079JddVZHwWjxVka6NMovlg25+WrjEZU+UWdv1saq6shzFeRN0jhHX+3bu+44X59NkIGiMWwxUfalFemLzgWqXoF4crWP+xQPPPJeSvoQ7MpW+9yg1DC/iHc4atBgkNa+4pfqonkDjzEhHmxMWqC+d0Y5GIslvPMiFqIBxdIJ0cJmOg/xoC7BvNck7jaeumj0+3eG768ezMiu5o1EFFMpRAMOtUYBZL3iNsFD28ECVhYYyP2HECF4BNB9VwwjI33BiG31iFAJaPgQOrUXy8gLTM80foJCV2mGhXZWznH/IgyHlqfbu6skMKywpX7y52NCyJ2sgnZByriOCaBZBR35hhzAuXJM2G2rvq39a49u4T4pvryOSirMFmEZhhUTta+wE9cX76uSHcgiCrsOgWZhkMAlJn7WFh0XkUqRP/598wuwGfLB9w4NP43yl2aLLKpRJXOKF69N4p4Uurv/oA4GTghhyE+3rkAOyhVk+5Uk/ZKvgIJKEOlwIPgzZQIwAPI6fEFiXJn5QiWM4xW0iMbj9HMM9Y6qa1Zqh4MPX4BrrKQfQZ7JHHa35HQd3LcX1VFB7fj341Ge4y4Id64wqqRs7k+1IVyB2Yyv1R5QCl9ftTIIs/Egbw== TechMeetsFinance@outlook.com' // PUT YOUR SSH KEY HERE run '''ssh-keygen -t rsa -b 4096 -C "TechMeetsFinance@outlook.com" -f ~/.ssh/azure_key'''
  }
}

// Public IP — static so it never changes between restarts
resource publicIp 'Microsoft.Network/publicIPAddresses@2025-05-01' = {
  name: 'pip-jumpbox-${env}'
  location: location
  sku: { name: sku }
  properties: { publicIPAllocationMethod: 'Static' }
}

// NSG — port 22 only from your IP
resource nsg 'Microsoft.Network/networkSecurityGroups@2025-05-01' = {
  name: 'nsg-jumpbox-${env}'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowSSHFromCorporateIP'
        properties: {
          priority: 100
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: corporateIpAddress
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
      {
        name: 'DenySSHAll'
        properties: {
          priority: 200
          protocol: 'Tcp'
          access: 'Deny'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
    ]
  }
}

// Network interface
resource nic 'Microsoft.Network/networkInterfaces@2025-05-01' = {
  name: 'nic-jumpbox-${env}'
  location: location
  properties: {
    networkSecurityGroup: { id: nsg.id }
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: { id: subnetId }
          publicIPAddress: { id: publicIp.id }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

// The Jump Box VM
resource jumpbox 'Microsoft.Compute/virtualMachines@2025-04-01' = {
  name: 'vm-jumpbox-${env}'
  location: location
  properties: {
    hardwareProfile: { vmSize: 'Standard_D2s_v3' }
    osProfile: {
      computerName: 'vm-jumpbox-${env}'
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: sshKey.properties.publicKey
            }
          ]
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'canonical'
        offer: 'ubuntu-24_04-lts'
        sku: 'server-gen1'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: { storageAccountType: 'Standard_LRS' }
        diskSizeGB: 32
      }
    }
    networkProfile: {
      networkInterfaces: [ { id: nic.id } ]
    }
  }
}

// Auto-shutdown at 22:00 to save cost overnight
resource autoShutdown 'Microsoft.DevTestLab/schedules@2018-09-15' = {
  name: 'shutdown-computevm-vm-jumpbox-${env}'
  location: location
  properties: {
    status: 'Enabled'
    taskType: 'ComputeVmShutdownTask'
    dailyRecurrence: { time: '2200' }
    timeZoneId: 'UTC'
    targetResourceId: jumpbox.id
  }
}

output publicIpAddress string = publicIp.properties.ipAddress
output vmName          string = jumpbox.name
output vmId            string = jumpbox.id