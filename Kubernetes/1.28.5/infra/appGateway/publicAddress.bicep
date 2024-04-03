@description('Required. Public IP Address resource name')
param name string

@description('Optional. Domain name label for public IP address')
param domainNameLabel string = 'ipaddress'

@description('Optional. Public IP Address is already existing')
param isExisting bool = true

var location = resourceGroup().location

resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2023-09-01' existing = if (isExisting) {
  name: name
  scope: resourceGroup()
}

resource publicIPAddressNew 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: name
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  zones: [
    '1'
  ]
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    dnsSettings: {
      domainNameLabel: domainNameLabel
    }
    ddosSettings: {
      protectionMode: 'VirtualNetworkInherited'
    }
  }
}

output name string = isExisting ? publicIPAddress.name : publicIPAddress.name
