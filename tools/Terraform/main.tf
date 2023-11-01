terraform {
  required_version = ">=1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.4.0"
    }
  }
}

provider "random" {}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

variable "environment" {
  type    = string
  default = "development"
}

variable "environment_variable_name" {
  type    = string
  default = "ASPNETCORE_ENVIRONMENT"
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "data_location" {
  type    = string
  default = "United States"
}

variable "app_code_name" {
  type = string
}

variable "log_analytics_workspace" {
  type = string
}

variable "user_assigned_identity_dapr" {
  type = string
}

variable "app_configuration" {
  type = string
}

variable "container_registry" {
  type = string
}
variable "container_registry_scope_map" {
  type = string
}
variable "container_registry_username" {
  type = string
}
variable "container_registry_token" {
  type = string
}

variable "container_app_environment" {
  type = string
}

variable "container_app_suffix_api" {
  type = string
}

locals {
  resource_group_name = "${var.app_code_name}-${var.environment}"
  container_app_api = "${var.app_code_name}-${var.container_app_suffix_api}"
}

resource "random_password" "password" {
  length  = 16
  special = true
  upper   = true
  numeric = true
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "environment" {
  name     = local.resource_group_name
  location = var.location
}


resource "azuread_application_registration" "application" {
  display_name = azurerm_resource_group.environment.name
}
resource "azuread_application_password" "application_password" {
  application_id = azuread_application_registration.application.id
  display_name          = "rbac"
}
resource "azuread_service_principal" "service_principal" {
	client_id                    = azuread_application_registration.application.client_id
  app_role_assignment_required = false
  use_existing                 = true
  description                  = "Continues-integration services 'deployment' account"
}
resource "azurerm_role_assignment" "role_assignment_contributor" {
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.service_principal.id
  scope                = azurerm_resource_group.environment.id
}
output "azuread_service_principal_credentials" {
  sensitive = true
  value = {
    clientId       : azuread_service_principal.service_principal.client_id
    clientSecret   : resource.azuread_application_password.application_password.value
    subscriptionId : data.azurerm_client_config.current.subscription_id
    tenantId       : azuread_service_principal.service_principal.application_tenant_id
  }
}


resource "azurerm_log_analytics_workspace" "log_analytics_workspace" {
  name                = var.log_analytics_workspace
  resource_group_name = azurerm_resource_group.environment.name
  location            = azurerm_resource_group.environment.location
  retention_in_days   = 30
  daily_quota_gb      = 0.5
}

resource "azurerm_role_assignment" "role_assignment_dapr" {
  role_definition_name = "App Configuration Data Reader"
  scope                = azurerm_app_configuration.app_configuration.id
  principal_id         = "c7444f6c-70e5-4b24-bbd4-31401b202d7f"
}
resource "azurerm_app_configuration" "app_configuration" {
  name                = var.app_configuration
  resource_group_name = azurerm_resource_group.environment.name
  location            = azurerm_resource_group.environment.location
  sku                 = "standard"
  #   sku                 = "free"
}


resource "azurerm_container_registry" "container_registry" {
  name                = var.container_registry
  resource_group_name = azurerm_resource_group.environment.name
  location            = azurerm_resource_group.environment.location
  sku                 = "Basic"
  admin_enabled       = true
}
output "container_registry_login_server" {
  value = azurerm_container_registry.container_registry.login_server
}
resource "azurerm_container_registry_scope_map" "container_registry_scope_map" {
  name                    = var.container_registry_scope_map
  resource_group_name     = azurerm_resource_group.environment.name
  container_registry_name = azurerm_container_registry.container_registry.name
  actions = [
    "repositories/${local.container_app_api}/content/read",
    "repositories/${local.container_app_api}/content/write"
  ]
}
resource "azurerm_container_registry_token" "container_registry_token" {
  name                    = var.container_registry_token
  resource_group_name     = azurerm_resource_group.environment.name
  container_registry_name = azurerm_container_registry.container_registry.name
  scope_map_id            = azurerm_container_registry_scope_map.container_registry_scope_map.id
}


resource "null_resource" "default_docker_image_pull_push" {
  provisioner "local-exec" {
    command = <<EOL
	  $image = "nginx:alpine";
    az acr login --name ${azurerm_container_registry.container_registry.name};
    $exists = az acr repository show --name ${azurerm_container_registry.container_registry.name} --image $image --output tsv 2>$null;
    if (-not $exists) {
      docker pull $image;
      docker tag $image ${azurerm_container_registry.container_registry.login_server}/$image;
      docker push ${azurerm_container_registry.container_registry.login_server}/$image;
	  }
    EOL
    environment = {
      DOCKER_CLI_AZURE_AUTH_MODE = "native"
    }
    interpreter = ["PowerShell", "-Command"]
  }
  triggers = {
    # always_run = "${timestamp()}"
    registry_id = azurerm_container_registry.container_registry.id
  }
  depends_on = [
    azurerm_container_registry.container_registry
  ]
}


resource "azurerm_container_app_environment" "container_app_environment" {
  name                       = var.container_app_environment
  location                   = azurerm_resource_group.environment.location
  resource_group_name        = azurerm_resource_group.environment.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics_workspace.id
  depends_on = [
    null_resource.default_docker_image_pull_push
  ]
}
resource "azurerm_user_assigned_identity" "user_assigned_identity_dapr" {
  name                = var.user_assigned_identity_dapr
  resource_group_name = azurerm_resource_group.environment.name
  location            = azurerm_resource_group.environment.location
}
resource "azurerm_container_app_environment_dapr_component" "dapr_component_configurationstore" {
  name                         = "configuration"
  container_app_environment_id = azurerm_container_app_environment.container_app_environment.id
  component_type               = "configuration.azure.appconfig"
  version                      = "v1"
  metadata {
    name  = "host"
    value = azurerm_app_configuration.app_configuration.endpoint
  }
  metadata {
    name  = "azureClientId"
    value = "003352ec-fdcd-48e1-8fab-7d9cc45c6195"
  }
  scopes = [
    var.container_app_suffix_api
  ]
}


resource "azurerm_container_app" "container_app_api" {
  name                         = local.container_app_api
  resource_group_name          = azurerm_resource_group.environment.name
  container_app_environment_id = azurerm_container_app_environment.container_app_environment.id
  revision_mode                = "Single"

  template {
    container {
      name   = var.container_app_suffix_api
      image  = "${azurerm_container_registry.container_registry.login_server}/nginx:alpine"
      cpu    = 0.25
      memory = "0.5Gi"
      env {
        name  = var.environment_variable_name
        value = var.environment
      }
      env {
        name        = "TestEnvironmentVariable"
        secret_name = "mysecret"
      }
    }
    min_replicas = 1
    max_replicas = 1
  }
   lifecycle {
    ignore_changes = [
      template[0].container[0].image,
    ]
  }
  secret {
    name  = "mysecret"
    value = azurerm_resource_group.environment.name
  }
  secret {
    name  = "registry-admin-password"
    value = azurerm_container_registry.container_registry.admin_password
  }
  registry {
    server               = azurerm_container_registry.container_registry.login_server
    username             = azurerm_container_registry.container_registry.admin_username
    password_secret_name = "registry-admin-password"
  }
  ingress {
    allow_insecure_connections = false
    external_enabled           = true
    target_port                = 80
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
  dapr {
    app_id       = var.container_app_suffix_api
    app_port     = 80
    app_protocol = "grpc"

  }
}
