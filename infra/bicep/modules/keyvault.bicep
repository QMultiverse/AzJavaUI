// infra/bicep/modules/keyvault.bicep

param env string
param location string

@secure()
param acrPassword string

// utcNow() is only valid as a parameter default — this is the correct pattern
param currentTime string = utcNow()

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'kv1-serenity-${env}'
  location: location
  properties: {
    sku: { family: 'A', name: 'standard' }
    tenantId: subscription().tenantId
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enableRbacAuthorization: true
  }
}

// Store ACR password — wired directly from acr.bicep output
resource acrPasswordSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
 parent: kv
 name: 'acr-password'
 properties: {
   value: acrPassword
   attributes: {
     // Alert fires 30 days before expiry (configured in monitoring.bicep)
     exp: dateTimeToEpoch(dateTimeAdd(currentTime, 'P90D'))
   }
 }
}
 

resource gridUrlSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: kv
  name: 'selenium-grid-url'
  properties: {
    value: 'placeholder-set-by-grid-deploy'
  }
}

output name string = kv.name
output id   string = kv.id