// infra/bicep/modules/storage.bicep
// Blob Storage with static website for Serenity HTML reports.

param env string
param location string

resource storage 'Microsoft.Storage/storageAccounts@2025-08-01' = {
  name: 'st2serenity${env}'
  location: location
  sku: { name: 'Standard_LRS' }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
  }
}

// Enable static website hosting for Serenity HTML reports
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2025-08-01' = {
  parent: storage
  name: 'default'
  properties: {
    cors: { corsRules: [] }
  }
}

// 90-day auto-delete lifecycle — keeps storage costs bounded
resource lifecycle 'Microsoft.Storage/storageAccounts/managementPolicies@2025-08-01' = {
  parent: storage
  name: 'default'
  properties: {
    policy: {
      rules: [
        {
          name: 'delete-old-reports'
          enabled: true
          type: 'Lifecycle'
          definition: {
            filters: { blobTypes: ['blockBlob'], prefixMatch: ['reports/'] }
            actions: {
              baseBlob: { delete: { daysAfterModificationGreaterThan: 90 } }
            }
          }
        }
      ]
    }
  }
}

output staticWebUrl string = storage.properties.primaryEndpoints.web