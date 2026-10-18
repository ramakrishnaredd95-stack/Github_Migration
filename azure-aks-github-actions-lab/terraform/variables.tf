variable "subscription_id" {
  description = "Azure subscription ID used by the azurerm provider."
  type        = string
}
variable "location" {
  description = "Azure region for the lab resources."
  type        = string
  default     = "centralindia"
}
variable "project" {
  description = "Short project identifier; keep it lowercase."
  type        = string
  default     = "shoplab"
}
variable "environment" {
  type    = string
  default = "dev"
}
variable "kubernetes_version" {
  description = "Use a Kubernetes version currently supported by AKS in your region."
  type        = string
  default     = null
}
variable "node_count" {
  type    = number
  default = 1
}
variable "node_vm_size" {
  type    = string
  default = "Standard_D2s_v5"
}
