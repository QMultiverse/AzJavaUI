// infra/bicep/modules/acr.bicep

param env string
param location string

@allowed(['Basic', 'Classic', 'Standard', 'Premium'])
param sku string = 'Basic'

resource acr 'Microsoft.ContainerRegistry/registries@2025-11-01' = {
  name: 'acrserenity${env}'
  location: location
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: true
  }
}

output loginServer string = acr.properties.loginServer
output name        string = acr.name
output acrPassword string = acr.listCredentials().passwords[0].value