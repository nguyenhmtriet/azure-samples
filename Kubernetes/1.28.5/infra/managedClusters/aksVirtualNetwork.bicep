@description('Required. Virtual network name')
param name string

@description('Required. Virtual subnet name')
param subnetName string

@description('Required. Address space prefix')
param addressSpacePrefix string

@description('Required. Subnet address prefix')
param subnetAddressPrefix string

var location = resourceGroup().location

resource vNet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: name
  location: location
  properties: {
    encryption: {
      enabled: false
      enforcement: 'AllowUnencrypted'
    }
    addressSpace: {
      addressPrefixes: [
        addressSpacePrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetAddressPrefix
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
    enableDdosProtection: false
  }
}

output name string = vNet.name
output subNetName string = vNet.properties.subnets[0].name
output subnetId string = vNet.properties.subnets[0].id
