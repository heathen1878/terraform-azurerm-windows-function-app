variable "windows_function_apps" {
  description = "A map of Windows Function Apps"
  default     = {}
  type = map(object(
    {
      name                = string
      resource_group_name = string
      location            = string
      service_plan_id     = string
      site_config = object(
        {
          always_on                = bool
          api_definition_url       = string
          api_management_api_id    = string
          app_command_line         = string
          app_scale_limit          = number
          application_insights_key = string
          application_stack = object(
            {
              dotnet_version              = string
              use_dotnet_isolated_runtime = bool
              java_version                = string
              node_version                = string
              powershell_core_version     = string
              use_custom_runtime          = bool
            }
          )
          app_service_logs = object(
            {
              disk_quota_mb         = number
              retention_period_days = number
            }
          )
          cors = object(
            {
              allowed_origins     = list(string)
              support_credentials = bool
            }
          )
          default_documents                 = list(string)
          elastic_instance_minimum          = number
          ftps_state                        = string
          health_check_eviction_time_in_min = number
          health_check_path                 = string
          http2_enabled                     = bool
          ip_restriction                    = list(string)
          load_balancing_mode               = string
          managed_pipeline_mode             = string
          minimum_tls_version               = string
          pre_warmed_instance_count         = number
          remote_debugging_enabled          = bool
          remote_debugging_version          = string
          runtime_scale_monitoring          = bool
          scm_ip_restriction                = list(string)
          scm_minimum_tls_version           = string
          scm_use_main_ip_restriction       = bool
          use_32_bit_worker                 = bool
          vnet_route_all_enabled            = bool
          websockets_enabled                = bool
          worker_count                      = number
        }
      )
      app_settings = map(any)
      auth_settings = object(
        {
          enabled = bool
        }
      )
      auth_settings_v2 = object(
        {}
      )
      backup = object(
        {
          enabled = bool
          name    = string
          schedule = object(
            {
              frequency_interval       = number
              frequency_unit           = string
              keep_at_least_one_backup = bool
              retention_period_days    = number
              start_time               = string
            }
          )
          storage_account_url = string
        }
      )
      builtin_logging_enabled            = bool
      client_certificate_enabled         = bool
      client_certificate_mode            = string
      client_certificate_exclusion_paths = string
      connection_string = object(
        {
          name  = string
          type  = string
          value = string
        }
      )
      deploy_slot                 = bool
      enabled                     = bool
      enable_private_endpoint     = bool
      functions_extension_version = string
      https_only                  = bool
      identity = object(
        {
          identity_ids = list(any)
          type         = string
        }
      )
      key_vault_reference_identity_id              = any
      private_dns_zone_ids                         = list(string)
      public_network_access_enabled                = bool
      sticky_settings                              = map(any)
      storage_account                              = map(any)
      storage_account_name                         = string
      storage_uses_managed_identity                = bool
      storage_account_access_key = string
      storage_account_id = string
      tags                                         = map(any)
      virtual_network_subnet_private_endpoint_id   = string
      virtual_network_subnet_integration_subnet_id = string
      zip_deploy_file                              = string
    }
  ))
}