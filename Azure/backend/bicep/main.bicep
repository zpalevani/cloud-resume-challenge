@description('Azure region for backend resources')
param location string = 'canadacentral'

@description('Globally unique storage account name (lowercase, no dashes)')
param storageAccountName string

@description('Function App name')
param functionAppName string

@description('App Service Plan name')
param planName string

// ----------------------------
// Storage Account
// ----------------------------
resource storage 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
  }
}

// ----------------------------
// Table Service
// ----------------------------
resource tableService 'Microsoft.Storage/storageAccounts/tableServices@2023-01-01' = {
  parent: storage
  name: 'default'
}

// ----------------------------
// Visitor Counter Table
// ----------------------------
resource counterTable 'Microsoft.Storage/storageAccounts/tableServices/tables@2023-01-01' = {
  parent: tableService
  name: 'VisitorCounter'
}

// ----------------------------
// App Service Plan (Consumption)
// ----------------------------
resource plan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: planName
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  kind: 'functionapp'
}

// ----------------------------
// Function App (Linux, runtime inferred)
// ----------------------------
resource functionApp 'Microsoft.Web/sites@2023-01-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: plan.id
    httpsOnly: true
    reserved: true
    siteConfig: {
      appSettings: [
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'python'
        }
        {
          name: 'TABLE_NAME'
          value: 'VisitorCounter'
        }
      ]
    }
  }
}

// ----------------------------
// Outputs
// ----------------------------
output functionAppName string = functionApp.name
output storageAccount string = storage.name
