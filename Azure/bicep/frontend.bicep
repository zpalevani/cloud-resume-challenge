param location string = 'eastus'
param rgName string
param storageName string
param afdProfileName string
param afdEndpointName string

// Storage account for static website
// NOTE: Static website is enabled via Azure CLI (not Bicep)
resource sa 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    accessTier: 'Hot'
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: true
  }
}

// Web endpoint looks like: https://<name>.z13.web.core.windows.net/
var webEndpoint = sa.properties.primaryEndpoints.web
var originHost = replace(replace(webEndpoint, 'https://', ''), '/', '')

// Azure Front Door Standard
resource afdProfile 'Microsoft.Cdn/profiles@2024-02-01' = {
  name: afdProfileName
  location: 'Global'
  sku: {
    name: 'Standard_AzureFrontDoor'
  }
}

resource afdEndpoint 'Microsoft.Cdn/profiles/afdEndpoints@2024-02-01' = {
  parent: afdProfile
  name: afdEndpointName
  location: 'Global'
  properties: {
    enabledState: 'Enabled'
  }
}

resource originGroup 'Microsoft.Cdn/profiles/originGroups@2024-02-01' = {
  parent: afdProfile
  name: 'og-static-site'
  properties: {
    healthProbeSettings: {
      probePath: '/'
      probeProtocol: 'Https'
      probeRequestType: 'GET'
      probeIntervalInSeconds: 120
    }
    loadBalancingSettings: {
      additionalLatencyInMilliseconds: 0
      sampleSize: 4
      successfulSamplesRequired: 3
    }
  }
}

resource origin 'Microsoft.Cdn/profiles/originGroups/origins@2024-02-01' = {
  parent: originGroup
  name: 'origin-storage-web'
  properties: {
    hostName: originHost
    httpPort: 80
    httpsPort: 443
    originHostHeader: originHost
    priority: 1
    weight: 1000
    enabledState: 'Enabled'
  }
}

resource route 'Microsoft.Cdn/profiles/afdEndpoints/routes@2024-02-01' = {
  parent: afdEndpoint
  name: 'route-static'
  properties: {
    originGroup: {
      id: originGroup.id
    }
    supportedProtocols: [
      'Http'
      'Https'
    ]
    httpsRedirect: 'Enabled'
    patternsToMatch: [
      '/*'
    ]
    forwardingProtocol: 'HttpsOnly'
    linkToDefaultDomain: 'Enabled'
    enabledState: 'Enabled'
  }
}

output storageWebEndpoint string = webEndpoint
output afdDefaultHostname string = '${afdEndpointName}.azurefd.net'
