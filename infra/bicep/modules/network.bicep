// infra/bicep/modules/network.bicep
// Creates VNet, subnet-jenkins, subnet-aci (ACI delegated).

param env string
param location string

resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: 'vnet-serenity-${env}'
  location: location
  properties: {
    addressSpace: { addressPrefixes: ['10.0.0.0/16'] }
    subnets: [
      {
        name: 'subnet-jenkins'
        properties: { addressPrefix: '10.0.1.0/24' }
      }
      {
        name: 'subnet-aci'
        properties: {
          addressPrefix: '10.0.2.0/24'
          // Delegate to ACI so containers join the VNet directly
          delegations: [
            {
              name: 'aci-delegation'
              properties: {
                serviceName: 'Microsoft.ContainerInstance/containerGroups'
              }
            }
          ]
        }
      }
    ]
  }
}

output jenkinsSubnetId string = vnet.properties.subnets[0].id
output aciSubnetId     string = vnet.properties.subnets[1].id
