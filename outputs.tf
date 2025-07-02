############################
# Outputs útiles
############################
output "policy_definition_id" {
  description = "ID de la definición de política"
  value       = azurerm_policy_definition.require_tags.id
}

output "policy_assignment_id" {
  description = "ID de la asignación aplicada a la suscripción"
  value       = azurerm_subscription_policy_assignment.require_tags.id
}