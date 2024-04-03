@description('Required. Azure Kubernetes Service name')
param name string

@description('Required. Application Gateway name')
param appGwName string

@description('Required. Application Gateway\'s virtual network name')
param appGwVNetName string

@description('Required. Application Gateway\'s subnet network name')
param appGwSubnetName string

@description('Required. User Managed Identity resource name')
param managedIdentityName string

@description('Required. AKS Cluster Node resource group name')
param nodeResourceGroupName string


resource appGw 'Microsoft.Network/applicationGateways@2023-09-01' existing = {
  name: appGwName
}

resource appGwVNet 'Microsoft.Network/virtualNetworks@2023-09-01' existing = {
  name: appGwVNetName
  scope: resourceGroup()

  resource appGwSubnet 'subnets' existing = {
    name: appGwSubnetName
  }
}


resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: managedIdentityName
  scope: resourceGroup()
}

resource ingressAppGwManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: 'ingressApplicationGateway-${name}'
  scope: resourceGroup(nodeResourceGroupName)
}

// assign Contributor role to ingressAppGwManagedIdentity in the Azure Application Gateway scope (within the current resource group)
resource contributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01'= {
  name: guid(resourceGroup().id, appGw.name, ingressAppGwManagedIdentity.name, 'contributorRoleAssigment', ingressAppGwManagedIdentity.id)
  scope: appGw
  properties: {
    principalId: ingressAppGwManagedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
    // Contributor
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
  }
}

// assign Reader role to ingressAppGwManagedIdentity within the current Resource Group scope 
resource readerRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01'= {
  name: guid(resourceGroup().id, resourceGroup().name, ingressAppGwManagedIdentity.name, 'readerRoleAssigment', ingressAppGwManagedIdentity.id)
  scope: resourceGroup()
  properties: {
    principalId: ingressAppGwManagedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
    // Reader
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')
  }
}

// assign Managed Identity Operator role to ingressAppGwManagedIdentity in scope of managed identity on the current Resource group
resource managedIdentityOperatorRoleAssigment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, ingressAppGwManagedIdentity.name, 'managedIdentityContributorRoleAssigment',  ingressAppGwManagedIdentity.id)
  scope: managedIdentity
  properties: {
    principalId: ingressAppGwManagedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
    // Managed Identity Operator
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'f1a07417-d97a-45cb-824c-7a7467783830')
  }
}

// assign Network Contributor role to ingressAppGwManagedIdentity in scope of Virtual Network's subnet 
// that containing Application Gateway on the current Resource group
resource networkContributorRoleAssigment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, ingressAppGwManagedIdentity.name, 'networkContributorRoleAssigment', ingressAppGwManagedIdentity.id)
  scope: appGwVNet::appGwSubnet
  properties: {
    principalId: ingressAppGwManagedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
    // Network Contributor
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '4d97b98b-1d4f-4787-a291-c67834d212e7')
  }
}
