@description('Required. Managed Identity name')
param name string

@description('Required. Key Vault name')
param keyVaultName string

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: name
  location: resourceGroup().location
}

resource managedIdentityContributorRoleAssigment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, managedIdentity.name, 'managedIdentityContributorRoleAssigment', managedIdentity.id)
  scope: managedIdentity
  properties: {
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
    // Managed Identity Contributor
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'e40ec5ca-96e0-45a2-b4ff-59039f2c2b59')
  }
}

resource getSecretAndGetCertificateAccessPolicies 'Microsoft.KeyVault/vaults/accessPolicies@2023-07-01' = {
  parent: keyVault
  name: 'add'
  properties: {
    accessPolicies: [
      {
        objectId: managedIdentity.properties.principalId
        tenantId: tenant().tenantId
        permissions: {
          secrets: [
            'get'
          ]
          certificates: [
            'get'
            'list'
          ]
        }
      }
    ]
  }
}

output managedIdentityPrincipalId string = managedIdentity.properties.principalId
output managedIdentityClientId string = managedIdentity.properties.clientId
output managedIdentityResourceId string = managedIdentity.id
