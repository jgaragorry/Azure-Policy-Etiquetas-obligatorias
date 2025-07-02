############################
# Terraform & Providers
############################
terraform {
  required_version = ">= 1.7"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.117"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {}
}

############################
# Auxiliar: sufijo aleatorio
############################
resource "random_string" "suffix" {
  length  = 4
  upper   = false
  special = false
}

############################
# Data source: suscripción actual
############################
data "azurerm_client_config" "current" {}

########################################
# 1️⃣ Definición de la política
########################################
locals {
  # Condiciones “la tag X no existe”
  missing_tags = [
    for tag in var.required_tags : {
      allOf = [
        { field = "type", notEquals = "Microsoft.Resources/subscriptions/resourceGroups" },
        { field = "tags.${tag}",     exists = false }
      ]
    }
  ]
}

resource "azurerm_policy_definition" "require_tags" {
  name         = "require-tags-${random_string.suffix.result}"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "🔒 Requiere etiquetas obligatorias"
  description  = "Deniega creación de recursos sin TODAS las tags requeridas."

  policy_rule = jsonencode({
    if   = { anyOf = local.missing_tags }
    then = { effect = "deny" }
  })
}

########################################
# 2️⃣ Asignación a la suscripción actual
########################################
resource "azurerm_subscription_policy_assignment" "require_tags" {
  name                 = "enforce-required-tags"
  subscription_id      = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  policy_definition_id = azurerm_policy_definition.require_tags.id

  display_name = "🔒 Enforce required tags"
  description  = "Impide crear recursos sin las etiquetas obligatorias."
}