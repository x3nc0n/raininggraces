targetScope = 'resourceGroup'

@description('Azure region for the Static Web App.')
param location string

@description('Main site Static Web App name.')
param staticWebAppName string

@description('Static Web App SKU name.')
param staticWebAppSkuName string = 'Free'

@description('GitHub repository URL connected to the Static Web App.')
param staticWebAppRepositoryUrl string

@description('GitHub branch connected to the Static Web App.')
param staticWebAppBranch string = 'master'

@secure()
@description('Optional GitHub token used by Azure when creating the repository connection.')
param staticWebAppRepositoryToken string = ''

param tags object = {}

var staticSiteProperties = union({
  allowConfigFileUpdates: true
  branch: staticWebAppBranch
  buildProperties: {
    appLocation: '/'
    outputLocation: '_site'
    skipGithubActionWorkflowGeneration: true
  }
  provider: 'GitHub'
  publicNetworkAccess: 'Enabled'
  repositoryUrl: staticWebAppRepositoryUrl
  stagingEnvironmentPolicy: 'Enabled'
}, empty(staticWebAppRepositoryToken) ? {} : {
  repositoryToken: staticWebAppRepositoryToken
})

resource staticSite 'Microsoft.Web/staticSites@2025-03-01' = {
  name: staticWebAppName
  location: location
  sku: {
    name: staticWebAppSkuName
    tier: staticWebAppSkuName
  }
  tags: tags
  properties: staticSiteProperties
}

output staticWebAppDefaultHostname string = staticSite.properties.defaultHostname
output staticWebAppId string = staticSite.id

@secure()
output staticWebAppApiToken string = list('${staticSite.id}/listSecrets', '2025-03-01').properties.apiKey
