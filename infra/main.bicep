targetScope = 'subscription'

@description('Azure deployment location for the subscription-scoped deployment record.')
param deploymentLocation string = 'southcentralus'

@description('Azure region for shared resources.')
param location string = 'southcentralus'

@description('Azure subscription identifier for tagging and documentation.')
param subscriptionId string = subscription().subscriptionId

@description('Azure tenant identifier for tagging and documentation.')
param tenantId string = subscription().tenantId

@description('Resource group name.')
param resourceGroupName string = 'rg-raininggraces'

@description('Main site Static Web App name.')
param staticWebAppName string = 'swa-raininggraces-main'

@description('Static Web App SKU name.')
param staticWebAppSkuName string = 'Free'

@description('GitHub repository URL for the main site.')
param staticWebAppRepositoryUrl string = 'https://github.com/x3nc0n/raininggraces'

@description('GitHub branch connected to the main site deployment.')
param staticWebAppBranch string = 'master'

@secure()
@description('Optional GitHub token used by Azure when creating the Static Web App repository connection.')
param staticWebAppRepositoryToken string = ''

var commonTags = {
  application: 'raininggraces'
  environment: 'production'
  location: location
  managedBy: 'github-actions'
  repository: 'x3nc0n/raininggraces'
  subscriptionId: subscriptionId
  tenantId: tenantId
  workload: 'main-site'
}

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: commonTags
}

module mainSite 'modules/main-site.bicep' = {
  name: 'main-site-${uniqueString(subscription().subscriptionId, resourceGroupName, staticWebAppName)}'
  scope: resourceGroup(rg.name)
  params: {
    location: location
    staticWebAppBranch: staticWebAppBranch
    staticWebAppName: staticWebAppName
    staticWebAppRepositoryToken: staticWebAppRepositoryToken
    staticWebAppRepositoryUrl: staticWebAppRepositoryUrl
    staticWebAppSkuName: staticWebAppSkuName
    tags: commonTags
  }
}

output deploymentLocation string = deploymentLocation
output resourceGroupName string = rg.name
output staticWebAppDefaultHostname string = mainSite.outputs.staticWebAppDefaultHostname
output staticWebAppId string = mainSite.outputs.staticWebAppId

@secure()
output staticWebAppApiToken string = mainSite.outputs.staticWebAppApiToken
