param(
  [string] $keyVaultName,
  [string] $resourceGroupName,
  [string] $aksName,
  [bool] $debug = $false
)

if ($debug -eq $true) {
  helm upgrade --install --debug --dry-run test MyK8sChart --namespace myk8schart-aks --create-namespace -f .\MyK8sChart\values.aks.yaml `
  --set-string secrets.azureKeyVault.name="$keyVaultName" `
  --set-string secrets.azureKeyVault.userAssignedManagedIdentity="$(az aks show -g \"$resourceGroupName\" -n \"$aksName\" --query addonProfiles.azureKeyvaultSecretsProvider.identity.clientId -o tsv)" `
  --set-string secrets.azureKeyVault.tenantId="$(az account show --query tenantId -o tsv)"

  return;
}

helm upgrade --install test MyK8sChart --namespace myk8schart-aks --create-namespace -f .\MyK8sChart\values.aks.yaml `
  --set-string secrets.azureKeyVault.name="$keyVaultName" `
  --set-string secrets.azureKeyVault.userAssignedManagedIdentity="$(az aks show -g \"$resourceGroupName\" -n \"$aksName\" --query addonProfiles.azureKeyvaultSecretsProvider.identity.clientId -o tsv)" `
  --set-string secrets.azureKeyVault.tenantId="$(az account show --query tenantId -o tsv)"