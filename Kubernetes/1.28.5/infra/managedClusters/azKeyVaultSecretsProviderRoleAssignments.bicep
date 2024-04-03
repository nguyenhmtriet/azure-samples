@description('Required. Azure Kubernetes Service name')
param name string

@description('Required. Key Vault name')
param keyVaultName string

@description('Required. AKS Cluster Node resource group name')
param nodeResourceGroupName string

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}


resource azKvSecretsProviderManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: 'azurekeyvaultsecretsprovider-${name}'
  scope: resourceGroup(nodeResourceGroupName)
}

resource getSecretAndGetCertificateAndGetKeysAccessPolicies 'Microsoft.KeyVault/vaults/accessPolicies@2023-07-01' = {
  parent: keyVault
  name: 'add'
  properties: {
    accessPolicies: [
      {
        objectId: azKvSecretsProviderManagedIdentity.properties.principalId
        tenantId: tenant().tenantId
        permissions: {
          keys: [
            'get'
          ]
          secrets: [
            'get'
          ]
          certificates: [
            'get'
          ]
        }
      }
    ]
  }
}
