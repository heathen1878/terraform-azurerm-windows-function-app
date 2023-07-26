resource "azurerm_windows_function_app" "windows_function_app" {
  for_each = var.windows_function_apps

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  service_plan_id     = each.value.service_plan_id

  site_config {
    always_on = each.value.site_config.always_on
  }

  identity {
    type         = each.value.identity.type
    identity_ids = each.value.identity.identity_ids
  }

  storage_account_name          = each.value.storage_account_name
  storage_uses_managed_identity = each.value.storage_uses_managed_identity
  functions_extension_version   = each.value.functions_extension_version

}

resource "azurerm_windows_function_app_slot" "windows_function_app" {

  for_each = {
    for key, value in var.windows_function_apps : key => value
    if value.deploy_slot == true
  }

  name            = "staging"
  function_app_id = azurerm_windows_function_app.windows_function_app[each.key].id
  site_config {
    always_on = each.value.site_config.always_on
  }
  storage_account_name          = each.value.storage_account_name
  storage_uses_managed_identity = each.value.storage_uses_managed_identity
  functions_extension_version   = each.value.functions_extension_version

}

resource "azurerm_private_endpoint" "windows_function_app" {
  for_each = {
    for key, value in var.windows_function_apps : key => value
    if value.enable_private_endpoint == true
  }

  name                          = format("pep-%s", each.value.name)
  location                      = each.value.location
  resource_group_name           = each.value.resource_group_name
  subnet_id                     = each.value.virtual_network_subnet_private_endpoint_id
  custom_network_interface_name = format("nic-%s", each.value.name)

  private_service_connection {
    name                           = format("pl-%s", each.value.name)
    private_connection_resource_id = azurerm_windows_function_app.windows_function_app[each.key].id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "privatelink.azurewebsites.net"
    private_dns_zone_ids = each.value.private_dns_zone_ids
  }

}

resource "azurerm_private_endpoint" "windows_function_app_slot" {
  for_each = {
    for key, value in var.windows_function_apps : key => value
    if value.deploy_slot == true && value.enable_private_endpoint == true
  }

  name                          = format("pep-staging-%s", each.value.name)
  location                      = each.value.location
  resource_group_name           = each.value.resource_group_name
  subnet_id                     = each.value.virtual_network_subnet_private_endpoint_id
  custom_network_interface_name = format("nic-staging-%s", each.value.name)

  private_service_connection {
    name                           = format("pl-staging-%s", each.value.name)
    private_connection_resource_id = azurerm_windows_function_app_slot.windows_function_app[each.key].id
    subresource_names              = ["sites-staging"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "privatelink.azurewebsites.net"
    private_dns_zone_ids = each.value.private_dns_zone_ids
  }

}

