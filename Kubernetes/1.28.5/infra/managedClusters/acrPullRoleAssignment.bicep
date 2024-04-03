@description('Required. Azure Kubernetes Service name')
param name string

@description('Required. AKS Cluster Node resource group name')
param nodeResourceGroupName string

@description('Required. Acr name')
param acrName string

@description('Required. Agent Pool principal id')
param agentPoolPrincipalId string

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: acrName
}

resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, acrName, agentPoolPrincipalId, 'acrPullRoleAssigment')
  scope: acr
  properties: {
    principalId: agentPoolPrincipalId
    principalType: 'ServicePrincipal'
    // Acr Pull
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
  }
}
