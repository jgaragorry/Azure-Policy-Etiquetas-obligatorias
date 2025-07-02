############################
# Variables de entrada
############################
variable "required_tags" {
  description = "Lista de etiquetas obligatorias"
  type        = list(string)
  default     = ["environment", "cost_center", "owner"]
}