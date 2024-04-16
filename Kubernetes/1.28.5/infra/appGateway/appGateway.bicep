var location = resourceGroup().location

@description('Required. Application Gateway resource name')
param name string

@description('Required. User Managed Identity resource name')
param managedIdentityName string

@description('Required. Virtual network name of Application Gateway')
param vNetName string

@description('Required. Subnet name of Application Gateway')
param subnetName string

@description('Required. Address space prefix')
param addressSpacePrefix string

@description('Required. Subnet address prefix')
param subnetAddressPrefix string

@description('Required. Key Vault name')
param keyVaultName string

@description('Required. Key Vault secret SSL Certificate name')
param keyVaultSecretSslCertificateName string

@description('Required. SSL Certificate name')
param certificateName string

@description('Required. Public IP Address resource name')
param publicIPAddrName string

@description('Required. Host name to listen in Application Gateway')
param hostName string

@description('Optional. Is existing Public IP Address. Default true')
param isPublicIPAddrExisting bool = true



var appGatewayName = name
var frontendIPConfigurationName = 'appGwPublicFrontendIpIPv4'
var frontendPort80Name = 'port_80'
var frontendPort443Name = 'port_443'
var httpSettingName = 'http-setting'
var httpsSettingName = 'https-setting'
var aksBackendPool = 'aks-backend'

var aksHttpsListenerName = 'aks-https-listener'
var aksHttpListenerName = 'aks-http-listener'

var aksHttpsRuleName = 'aks-https-rule'
var aksHttpRuleName = 'aks-http-rule'

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: managedIdentityName
  scope: resourceGroup()
}

module vNet 'appGatewayVirtualNetwork.bicep' = {
  name: '${deployment().name}-vNet'
  params: {
    name: vNetName
    subnetName: subnetName
    addressSpacePrefix: addressSpacePrefix
    subnetAddressPrefix: subnetAddressPrefix
  }
}

module ipAddress 'publicAddress.bicep' = {
  name: '${deployment().name}-publicIpAddr'
  params: {
    name: publicIPAddrName
    isExisting: isPublicIPAddrExisting
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName

  resource secret 'secrets' existing = {
    name: keyVaultSecretSslCertificateName
  }
}

resource appGateway 'Microsoft.Network/applicationGateways@2023-09-01' = {
  name: appGatewayName
  location: location
  zones: [
    '1'
  ]
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    sku: {
      name: 'Standard_v2'
      tier: 'Standard_v2'
      capacity: 1
    }
    enableHttp2: true
    probes: []
    trustedRootCertificates: []
    trustedClientCertificates: []
    sslProfiles: []
    loadDistributionPolicies: []
    backendSettingsCollection: []
    listeners: []
    urlPathMaps: []
    routingRules: []
    rewriteRuleSets: [
      {
        name: 'IngressRewriteSet'
        properties: {
          rewriteRules: [
            {
              name: 'FromIngressRule'
              ruleSequence: 100
              actionSet: {
                requestHeaderConfigurations: [
                  {
                    headerName: 'from-ingress'
                    headerValue: 'true'
                  }
                ]
              }
            }
          ]
        }
      }
    ]
    privateLinkConfigurations: []
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vNet.outputs.name, vNet.outputs.subNetName)
          }
        }
      }
    ]
    sslCertificates: [
      {
        name: certificateName
        properties: {
          keyVaultSecretId: keyVault::secret.properties.secretUri
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: frontendIPConfigurationName
        // "type": "Microsoft.Network/applicationGateways/frontendIPConfigurations",
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', ipAddress.outputs.name)
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: frontendPort80Name
        // type: 'Microsoft.Network/applicationGateways/frontendPorts'
        properties: {
          port: 80
        }
      }
      {
        name: frontendPort443Name
        // type: 'Microsoft.Network/applicationGateways/frontendPorts'
        properties: {
          port: 443
        }
      }
    ]
    backendAddressPools: [
      {
        name: aksBackendPool
        // type: 'Microsoft.Network/applicationGateways/backendAddressPools'
        properties: {
          backendAddresses: []
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: httpSettingName
        // type: 'Microsoft.Network/applicationGateways/backendHttpSettingsCollection'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress : false
          requestTimeout: 20
        }
      }
      {
        name: httpsSettingName
        // type: 'Microsoft.Network/applicationGateways/backendHttpSettingsCollection'
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress : true
          requestTimeout: 20
        }
      }
    ]
    httpListeners: [
      {
        name: aksHttpsListenerName
        // type: 'Microsoft.Network/applicationGateways/httpListeners'
        properties: {
          protocol: 'Https'
          requireServerNameIndication: true
          hostNames: [
            '*.${hostName}'
            '${hostName}'
          ]
          customErrorConfigurations: []
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appGatewayName, frontendIPConfigurationName)
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appGatewayName, frontendPort443Name)
          }
          sslCertificate: {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', appGatewayName, certificateName)
          }
        }
      }
      {
        name: aksHttpListenerName
        // type: 'Microsoft.Network/applicationGateways/httpListeners'
        properties: {
          protocol: 'Http'
          requireServerNameIndication: false
          hostNames: [
            '*.${hostName}'
            '${hostName}'
          ]
          customErrorConfigurations: []
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appGatewayName, frontendIPConfigurationName)
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appGatewayName, frontendPort80Name)
          }
        }
      }
    ]
    requestRoutingRules: [
      {
        name: aksHttpsRuleName
        // type: 'Microsoft.Network/applicationGateways/requestRoutingRules'
        properties: {
          ruleType: 'Basic'
          priority: 1
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appGatewayName, aksHttpsListenerName)
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGatewayName, aksBackendPool)
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGatewayName, httpsSettingName)
          }
        }
      }
      {
        name: aksHttpRuleName
        // type: 'Microsoft.Network/applicationGateways/requestRoutingRules'
        properties: {
          ruleType: 'Basic'
          priority: 2
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appGatewayName, aksHttpListenerName)
          }
          redirectConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/redirectConfigurations', appGatewayName, aksHttpRuleName)
          }
        }
      }
    ]
    redirectConfigurations: [
      {
        name: aksHttpRuleName
        // type: 'Microsoft.Network/applicationGateways/redirectConfigurations'
        properties: {
          redirectType: 'Permanent'
          targetListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appGatewayName, aksHttpsListenerName)
          }
          includePath: true
          includeQueryString: true
          requestRoutingRules: [
            {
              id: resourceId('Microsoft.Network/applicationGateways/requestRoutingRules', appGatewayName, aksHttpRuleName)
            }
          ]
        }
      }
    ]
  }
}
