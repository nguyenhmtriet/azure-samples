@description('Required. Azure Kubernetes Service name')
param name string

@description('Required. Virtual network name')
param vNetName string

@description('Required. Subnet name of Virtual network')
param subnetName string

@description('Required. Azure Container Registry name')
param acrName string

@description('Required. Address space prefix')
param addressSpacePrefix string

@description('Required. Subnet address prefix')
param subnetAddressPrefix string

@description('Required. Service CIDR')
param serviceCidr string

@description('Required. Dns service IP')
param dnsServiceIP string

@description('Required. User Managed Identity resource name')
param managedIdentityName string

@description('Required. Application Gateway name')
param appGwName string

@description('Required. Application Gateway\'s virtual network name')
param appGwVNetName string

@description('Required. Application Gateway\'s subnet network name')
param appGwSubnetName string

@description('Required. Key Vault name')
param keyVaultName string

@description('Required. Key Vault name')
param nodeResourceGroupName string

@description('Required. Log Analytics Workspace name')
param logAnalyticsWorkspaceName string

@description('Optional. DNS Prefix name')
param dnsPrefixName string = 'my-aks-dns'

var location = resourceGroup().location

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: logAnalyticsWorkspaceName
}

resource appGw 'Microsoft.Network/applicationGateways@2023-09-01' existing = {
  name: appGwName
}

module vNet 'aksVirtualNetwork.bicep' = {
  name: '${deployment().name}-vNet'
  params: {
    name: vNetName
    subnetName: subnetName
    addressSpacePrefix: addressSpacePrefix
    subnetAddressPrefix: subnetAddressPrefix
  }
}

resource aks 'Microsoft.ContainerService/managedClusters@2024-01-01' = {
  name: name
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'Base'
    tier: 'Free'
  }
  properties: {
    kubernetesVersion: '1.28.5'
    enableRBAC: true
    dnsPrefix: dnsPrefixName
    nodeResourceGroup: nodeResourceGroupName
    disableLocalAccounts: false
    autoUpgradeProfile: {
      upgradeChannel: 'patch'
      nodeOSUpgradeChannel: 'None'
    }
    agentPoolProfiles: [
      {
        name: 'sys'
        osDiskSizeGB: 128
        count: 1
        enableAutoScaling: false
        enableNodePublicIP: false
        enableFIPS: false
        vmSize: 'Standard_B2s'
        osType: 'Linux'
        osSKU: 'Ubuntu'
        type: 'VirtualMachineScaleSets'
        mode: 'System'
        maxPods: 30
        vnetSubnetID: vNet.outputs.subnetId
      }
      {
        name: 'ubulinux'
        osDiskSizeGB: 128
        count: 1
        enableAutoScaling: false
        enableNodePublicIP: false
        enableFIPS: false
        vmSize: 'Standard_B2s'
        osType: 'Linux'
        osSKU: 'Ubuntu'
        type: 'VirtualMachineScaleSets'
        mode: 'User'
        maxPods: 30
        availabilityZones: []
        vnetSubnetID: vNet.outputs.subnetId
      }
    ]
    addonProfiles: {
      azureKeyvaultSecretsProvider: {
        enabled: true
        config: {
          enableSecretRotation: 'true'
        }
      }
      omsagent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: logAnalyticsWorkspace.id
        }
      }
      ingressApplicationGateway: {
        enabled: true
        config: {
          applicationGatewayId: appGw.id
        }
      }
    }
    networkProfile: {
      networkPlugin: 'azure'
      networkDataplane: 'azure'
      loadBalancerSku: 'Standard'
      outboundType: 'loadBalancer'
      serviceCidr: serviceCidr
      dnsServiceIP: dnsServiceIP
    }
  }

  resource _ 'maintenanceConfigurations@2024-01-01' = {
    name: 'aksManagedAutoUpgradeSchedule'
    properties: {
      maintenanceWindow: {
        schedule: {
          daily: null
          weekly: {
            intervalWeeks: 1
            dayOfWeek: 'Sunday'
          }
          absoluteMonthly: null
          relativeMonthly: null
        }
        durationHours: 4
        utcOffset: '-04:00' // EST time zone
        startTime: '04:00' // start at 4AM UTC => With offset GMT-4 is relevant to 00:00 AM EST
      }
    }
  }
}

module acrPullRoleAssignment 'acrPullRoleAssignment.bicep' = {
  name: '${deployment().name}-acrPullRoleAssignment'
  dependsOn: [aks]
  params: {
    name: name
    nodeResourceGroupName: nodeResourceGroupName
    agentPoolPrincipalId: reference('Microsoft.ContainerService/managedClusters/${name}', '2024-01-01').identityProfile.kubeletidentity.objectId
    acrName: acrName
  }
}

module ingressAppGwManagedIdentityRoleAssigments 'ingressAppGwManagedIdentityRoleAssignments.bicep' = {
  name: '${deployment().name}-ingressAppGwManagedIdentityRoleAssignments'
  dependsOn: [aks]
  params: {
    name: name
    appGwName: appGwName
    appGwVNetName: appGwVNetName
    appGwSubnetName: appGwSubnetName
    managedIdentityName: managedIdentityName
    nodeResourceGroupName: nodeResourceGroupName
  }
}

module azKvSecretProviderRoleAssignments 'azKeyVaultSecretsProviderRoleAssignments.bicep' = {
  name: '${deployment().name}-azKvSecretsProviderRoleAssignments'
  dependsOn: [aks]
  params: {
    name: name
    keyVaultName: keyVaultName
    nodeResourceGroupName: nodeResourceGroupName
  }
}
