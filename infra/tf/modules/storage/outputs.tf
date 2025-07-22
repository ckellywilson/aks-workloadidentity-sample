output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.main.name
}

output "storage_account_id" {
  description = "ID of the storage account"
  value       = azurerm_storage_account.main.id
}

output "primary_blob_endpoint" {
  description = "Primary blob endpoint"
  value       = azurerm_storage_account.main.primary_blob_endpoint
}

output "app_data_container_name" {
  description = "Name of the application data container"
  value       = azurerm_storage_container.app_data.name
}

output "private_endpoint_ip" {
  description = "Private IP address of the storage private endpoint"
  value       = azurerm_private_endpoint.storage.private_service_connection[0].private_ip_address
}

output "private_dns_zone_name" {
  description = "Name of the private DNS zone"
  value       = azurerm_private_dns_zone.storage.name
}
