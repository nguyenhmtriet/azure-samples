var keyVaultName = '<your_keyVault_name>'
var publicIPAddrName = '<your_publicIpAddress_name>'
var managedIdentityName = '<your_managedIdentity_name>'
var logAnalyticsWorkspaceName = '<your_logAnalyticsWorkspace_name>'

var appGwName = '<your_appGateway_name>'

var appGwVNetName = '<your_appGatewayVNet_name>'
var appGwSubnetName = 'appGatewaySubnet'
var appGwAddressSpacePrefix = '10.10.10.0/24'
var appGwSubnetAddressPrefix = '10.10.10.0/24'
var hostName = '<your_hostname_matching_SSL_certificate>'

var aksName = '<your_aks_name>'
var nodeResourceGroupName = 'MC_<your-resource-group>_<your-aks-name>_<your-region>'
var vNetAksName = '<your_aksVNet_name>'
var subnetAksName = 'aksSubnet'
var vNetAksAddressSpacePrefix = '10.0.0.0/16'
var vNetAksSubnetAddressPrefix = '10.0.0.0/20'
var aksServiceCidr = '10.30.0.0/16'
var aksDnsServiceIP = '10.30.0.10'

var acrName = '<your_AzureContainerRegistry_name>'

module managedIdentity 'userAssignedIdentities/managedIdentity.bicep' = {
  name: '${deployment().name}-managedIdentity'
  params: {
    name: managedIdentityName
    keyVaultName: keyVaultName
  }
}

module appGateway 'appGateway/appGateway.bicep' = {
  name: '${deployment().name}-appGateway'
  params: {
    name: appGwName
    managedIdentityName: managedIdentityName
    vNetName: appGwVNetName
    subnetName: appGwSubnetName
    addressSpacePrefix: appGwAddressSpacePrefix
    subnetAddressPrefix: appGwSubnetAddressPrefix
    certificateName: '<your_hostname_matching_SSL_certificate>-appGwSsl'
    keyVaultName: keyVaultName
    keyVaultSecretSslCertificateName: '<your_hostname_matching_SSL_certificate>-certificateName'
    publicIPAddrName: publicIPAddrName
    hostName: hostName
    isPublicIPAddrExisting: true
  }
}

module aks 'managedClusters/aks.bicep' = {
  name: '${deployment().name}-aks'
  dependsOn: [appGateway]
  params: {
    name: aksName
    vNetName: vNetAksName
    subnetName: subnetAksName
    acrName: acrName
    addressSpacePrefix: vNetAksAddressSpacePrefix
    subnetAddressPrefix: vNetAksSubnetAddressPrefix
    serviceCidr: aksServiceCidr
    dnsServiceIP: aksDnsServiceIP
    managedIdentityName: managedIdentityName
    appGwName: appGwName
    appGwVNetName: appGwVNetName
    appGwSubnetName: appGwSubnetName
    keyVaultName: keyVaultName
    nodeResourceGroupName: nodeResourceGroupName
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
  }
}

module vNetPeering 'virtualNetworks/virtualNetworkPeering.bicep' = {
  name: '${deployment().name}-vNetPeering'
  dependsOn: [aks, appGateway]
  params: {
    vnet1Name: vNetAksName
    vnet2Name: appGwVNetName
    peering1Name: 'aks'
    peering2Name: 'appGw'
  }
}
