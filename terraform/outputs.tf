output "resource_group_name" {
  value = azurerm_resource_group.main.name
}
output "acr_name" {
  value = azurerm_container_registry.main.name
}
output "acr_login_server" {
  value = azurerm_container_registry.main.login_server
}
output "aks_name" {
  value = azurerm_kubernetes_cluster.main.name
}
output "location" {
  value = azurerm_resource_group.main.location
}
output "acr_name" {
  value = azurerm_container_registry.acr.name
}

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "aks_name" {
  value = azurerm_kubernetes_cluster.aks.name
}