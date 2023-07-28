resource "azurerm_windows_function_app" "windows_function_app" {
  for_each = var.windows_function_apps

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  service_plan_id     = each.value.service_plan_id

  site_config {
    always_on                = each.value.site_config.always_on
    api_definition_url       = each.value.site_config.api_definition_url
    api_management_api_id    = each.value.site_config.api_management_api_id
    app_command_line         = each.value.site_config.app_command_line
    app_scale_limit          = each.value.site_config.app_scale_limit
    application_insights_key = each.value.site_config.application_insights_key

    dynamic "application_stack" {
      for_each = each.value.site_config.application_stack.use_custom_runtime == true ? { "application_stack" = "use_custom_runtime" } : {}

      content {
        use_custom_runtime = each.value.application_stack.use_custom_runtime
      }
    }

    dynamic "application_stack" {
      for_each = each.value.site_config.application_stack.dotnet_version != null ? { "application_stack" = "dotnet" } : {}

      content {
        dotnet_version              = each.value.site_config.application_stack.dotnet_version
        use_dotnet_isolated_runtime = each.value.site_config.application_stack.use_dotnet_isolated_runtime
      }
    }

    dynamic "application_stack" {
      for_each = each.value.site_config.application_stack.java_version != null ? { "application_stack" = "java" } : {}

      content {
        java_version = each.value.site_config.application_stack.java_version
      }
    }

    dynamic "application_stack" {
      for_each = each.value.site_config.application_stack.node_version != null ? { "application_stack" = "node" } : {}

      content {
        node_version = each.value.site_config.application_stack.node_version
      }
    }

    dynamic "application_stack" {
      for_each = each.value.site_config.application_stack.powershell_core_version != null ? { "application_stack" = "powershell" } : {}

      content {
        powershell_core_version = each.value.site_config.application_stack.powershell_core_version
      }
    }

    app_service_logs {
      disk_quota_mb         = each.value.site_config.app_service_logs.disk_quota_mb
      retention_period_days = each.value.site_config.app_service_logs.retention_period_days

    }

    dynamic "cors" {
      for_each = length(each.value.site_config.cors.allowed_origins) != 0 ? { "cors" = "enabled" } : {}

      content {
        allowed_origins     = each.value.site_config.cors.allowed_origins
        support_credentials = each.value.site_config.cors.support_credentials
      }
    }

    default_documents                 = each.value.site_config.default_documents
    elastic_instance_minimum          = each.value.site_config.elastic_instance_minimum
    ftps_state                        = each.value.site_config.ftps_state
    health_check_eviction_time_in_min = each.value.site_config.health_check_eviction_time_in_min
    health_check_path                 = each.value.site_config.health_check_path
    http2_enabled                     = each.value.site_config.http2_enabled
    load_balancing_mode               = each.value.site_config.load_balancing_mode
    managed_pipeline_mode             = each.value.site_config.managed_pipeline_mode
    minimum_tls_version               = each.value.site_config.minimum_tls_version
    pre_warmed_instance_count         = each.value.site_config.pre_warmed_instance_count
    remote_debugging_enabled          = each.value.site_config.remote_debugging_enabled
    remote_debugging_version          = each.value.site_config.remote_debugging_version
    runtime_scale_monitoring_enabled  = each.value.site_config.runtime_scale_monitoring
    use_32_bit_worker                 = each.value.site_config.use_32_bit_worker
    vnet_route_all_enabled            = each.value.site_config.vnet_route_all_enabled
    websockets_enabled                = each.value.site_config.websockets_enabled
    worker_count                      = each.value.site_config.worker_count
  }

  app_settings = merge(each.value.app_settings, {
    WEBSITE_CONTENTSHARE                     = format("%s-content", substr(each.value.name, 5, -1)),
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING = format("DefaultEndpointsProtocol=https;AccountName=%s;AccountKey=%s;EndpointSuffix=core.windows.net", format("st%s", substr(each.value.name, 5, -1)), each.value.storage_account_access_key)
  })

  functions_extension_version = each.value.functions_extension_version

  identity {
    type         = each.value.identity.type
    identity_ids = each.value.identity.identity_ids
  }

  storage_account_access_key = each.value.storage_account_access_key
  storage_account_name       = each.value.storage_account_name

  virtual_network_subnet_id = each.value.virtual_network_subnet_integration_subnet_id

}

# TODO: Not yet implemented
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

# TODO: Not yet implemented
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

resource "azurerm_role_assignment" "windows_function_app" {
  for_each = var.windows_function_apps

  scope                = each.value.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_windows_function_app.windows_function_app[each.key].identity[0].principal_id
}

