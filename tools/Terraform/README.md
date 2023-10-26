# Snippets

## Set azure account

```powershell
az account list --output table;
az account set --subscription "Visual Studio Enterprise Subscription";
```

## Init

```powershell
terraform init;
```

## Plan

```powershell
# terraform plan -var environment="environment" -var-file="./env/environment.tfvars" -out "environment.tfplan";
# terraform apply "environment.tfplan" -var-file="./env/environment.tfvars";
terraform plan -var-file="./env/production.tfvars" -out "production.tfplan";
terraform apply "production.tfplan";
```

## Output Sensitive Values

> [!NOTE] 
> Set the values below in the environment secrets in GitHub Actions as `AZURE_CONTAINERREGISTRY_CREDENTIALS` and `AZURE_CONTAINERREGISTRY`

```powershell
terraform output -json azuread_service_principal_credentials;
terraform output container_registry_login_server;
```

## Destroy

```powershell
# terraform destroy -var-file="./env/environment.tfvars";
terraform destroy -var-file="./env/production.tfvars";
```

### Destroy with plan
```powershell
# terraform plan -destroy -var-file="./env/environment.tfvars" -out "environment.destroy.tfplan";
# terraform apply "environment.destroy.tfplan";
terraform plan -destroy -var-file="./env/production.tfvars" -out "production.destroy.tfplan";
terraform apply "production.destroy.tfplan";
```

## Import

```powershell
# terraform import azurerm_container_app.example "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/resGroup1/providers/Microsoft.App/containerApps/myContainerApp"
```
