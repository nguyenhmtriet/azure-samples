@description('Required. Virtual network name 1')
param vnet1Name string

@description('Required. Virtual network name 2')
param vnet2Name string

@description('Required. Peering name 1')
param peering1Name string

@description('Required. Peering name 2')
param peering2Name string

resource vnet1 'Microsoft.Network/virtualNetworks@2023-09-01' existing = {
  name: vnet1Name
}

resource vnet2 'Microsoft.Network/virtualNetworks@2023-09-01' existing = {
  name: vnet2Name
}

resource vnetPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-09-01' = {
  name: '${peering1Name}-p2p-${peering2Name}'
  parent: vnet1
  properties: {
    peeringSyncLevel: 'FullyInSync'
    remoteVirtualNetwork: {
      id: vnet2.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    doNotVerifyRemoteGateways: false
  }
}

resource vnetPeeringReverse 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-09-01' = {
  name: '${peering2Name}-p2p-${peering1Name}'
  parent: vnet2
  properties: {
    peeringSyncLevel: 'FullyInSync'
    remoteVirtualNetwork: {
      id: vnet1.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    doNotVerifyRemoteGateways: false
  }
}
