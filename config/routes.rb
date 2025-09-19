require "sidekiq/pro/web"

# Configure Sidekiq-specific session middleware
Sidekiq::Web.use ActionDispatch::Cookies
Sidekiq::Web.use ActionDispatch::Session::CookieStore, key: "_interslice_session"


CloudStreet::API::Application.routes.draw do

  get '/.well-known/:id', to: 'private/oidc/discovery#show'

  match 'oidc/authorizations' => 'private/oidc/authorizations#create', via: [:get, :post]
  get 'oidc/user_info', to: 'private/oidc/user_infos#show'
  # get 'sessions/logout', to: 'sessions#destroy', as: :end_session

  # post 'oidc/tokens', to: proc { |env| OIDCProvider::TokenEndpoint.new.call(env) }
  post 'oidc/tokens', to: 'private/oidc/tokens#create'
  # get 'jwks.json', as: :jwks, to: proc { |env| [200, {'Content-Type' => 'application/json'}, [OIDCProvider::IdToken.config[:jwk_set].to_json]] }

  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  mount Flipper::UI.app(Flipper,{ rack_protection: { except: %i[authenticity_token form_token json_csrf remote_token http_origin session_hijacking] } }){|builder|
      builder.use Rack::Auth::Basic do |username, password|
        username == ENV['FLIPPER_USERNAME'] && password == ENV['FLIPPER_PASSWORD']
      end
      }, at: "flipper"

  constraints(lambda { |req| ENV["SAAS_ENV"].eql?("true") || ENV["ORG_SETUP"].eql?("complete") }) do
    namespace :marketplace do
      get "settings" => "settings#settings"
      # post "verify_db_details" => "settings#verify_db_details"
      post "verify_internet_connection" => "settings#verify_internet_connection"
      post "verify_smtp_connection" => "settings#verify_smtp_config"
      post "update_network_proxy"  => "settings#update_network_proxy"
      post "update_smtp_config"  => "settings#update_smtp_config"
      post "export_data_to_s3"  => "settings#export_data_to_s3"  , as: 'export_data_to_s3_path'
      post "import_database_from_s3"  => "settings#import_database_from_s3" , as: 'import_mongodb_from_s3_path'
      get "check_status" => 'settings#check_status'
      post "update_ssl_cert" => "settings#update_ssl_cert"
      post "verify_dns_connection" => "settings#verify_dns_connection"
      post "update_dns_config" => "settings#update_dns_config"
    end

    resource :upgrades, only: [:index], module: 'marketplace' do
      collection do
        get "latest_release_info"
        get "analyse_for_upgrade"
        post "init"
      end
    end

    resource :user, only: [] do
      collection do
        put 'update_profile'
        put 'update_preferred_currency'
      end
    end

    post "request_demo" => "private/request_demo#request_demo"
    namespace :private do
      namespace :mira do
        resource :sessions,only: [] do
          collection do
            get :verify_csmp_token
          end
        end
      end
      namespace :oidc do
        resource :sessions, only: [:create]
      end
      resource :sessions,        only: [:create] do
        collection do
          get :token_verify
          post :get_organisation_list
          post :member_login
          post :disable_member_login
          post :logout
        end
      end
      resource :users,           only: [:create] do
        collection do
          post "confirm"
          post "resend_confirmation"
          post "super_secret_confirm"
          get  "validate_subdomain"
          post "disable_mfa_notification"
          put  "disable_mfa"
          get  "validate_invitation"
          get  "check_register_subdomain"
        end
      end
      resource :invites,         only: [:create, :show] do
        collection do
          get "exists"
        end
      end
      resource :reset_passwords, only: [:create, :update]
      resources :saml, only: :index do
        collection do
          post "acs"
          post "sso"
          post "metadata"
          get "metadata"
          post "logout"
          get  "disable"
          get  "login"
        end
      end

    end

    namespace :admin do
      get  "invites"
      post "invites"
    end
    Sidekiq::Web.use Rack::Auth::Basic do |username, password|
      username == 'admin' && password == 'admin@123'
    end
    mount Sidekiq::Web => "sidekiq"

    # existing_value = ENV["DOCKER_SIDEKIQ"]
    # ENV["DOCKER_SIDEKIQ"] = "true"
    # redis_config = Rails.application.config_for(:redis)
    # mount Sidekiq::Pro::Web.with(redis_pool: ConnectionPool.new { Redis.new(:url => "redis://#{redis_config['host']}:#{redis_config['port']}/#{redis_config['db']}") }), at: '/docker-sidekiq', as: 'docker-sidekiq'
    # ENV["DOCKER_SIDEKIQ"] = existing_value

    resources :groups, only: [:index, :show, :create] do
      member do
        post "add"
        post "remove"
        post "invite"
      end
    end

    namespace :vm_ware do
      resources :budgets do
        collection do
          get :get_default_currency
          get :get_billing_tenants_list
          get :download_budget_data
        end
        member do
          post :share_budget
        end
        collection do
          post :process_budget
        end
      end
      resources :vcenters, only: :index do
        get :available_disks, on: :collection
        post :reprocess_vmware_data, on: :collection
      end
      resources :metrics, only: [] do
        collection do
          post :search
          post :search_info
        end
      end
      resources :events, only: %i[index create]
      resources :tokens, only: %i[create]
      resources :rate_cards
      get :rate_card_history, to: 'rate_cards#history'
    end

    resources :tags do
      member do
        post 'archive_tag'
      end
    end

    resources :environment_tags do
      member do
        get 'get_env_tags'
      end

      collection do
        get 'search'
      end
    end

    resources :encryption_keys, only:[:index, :sync_encryption_keys] do
      collection do
        get :sync_encryption_keys
        get :list_encryption_keys
      end
    end
    resources :template_costs, only: [:index]

    resources :pdf, only: [] do
      collection do
        get 'environment_export'
        post 'template_export'
        get 'download_template'
      end
    end

    resources :service_naming_defaults, only: [:index] do
      collection do
        post 'update_service_names'
      end
    end

    resources :users do
      member do
        put 'disable_intro'

        post "invite"
      end
      collection do
        get "module_list"
        post 'enable_disable_member'
        put 'reset_password'
        put 'change_user_preference'
        post 'assign_tenants'
        put 'enable_disable_mfa'
        put  'update_tenant_permission'
        get  "get_email_suggesion"
        put 'remove_tenants'
        get "get_adapters_status"
        get "is_processed_adapter_present"
        get "preferred_currency_alert"
        put "set_popup_preference"
        get "get_invite_link"
      end
    end

    resources :app_access_secrets, only: [:index, :create, :destroy] do
      member do
        put 'enable_disable'
      end
    end

    resources :user_activities, only: [:show,:index]
    resources :keys

    resources :backup_policies do
      collection do
        post 'schedule_backup'
      end
      member do
        put 'remove'
      end
    end

    resources :synchronization_logs do
      collection do
        get 'list_syncronizations'
        get 'search_logs'
      end
    end

    resources :organisation_settings, only: [:index,:update, :show]
    resources :alerts, only: [:index] do
      collection do
        put 'mark_viewed'
      end
    end

    resources :templates do
      collection do
        get "designer"
        get "directory_services"
        get "dettached_directory_services"
        post 'provision_sync_services'
        post 'list_iam_roles'
        post "copy_template"
        post 'copy_template_from_revision'
        get 'copy_template_info'
        get 'get_overriden_service_tags'
        post 'create_generic_template'
        post ':id' => 'templates#update'
        get 'generic_directory_services'
      end
      member do
        get 'revisions'
        post "destroy"
        post "publish"
        post "provision"
        post "provision_generic_template"
        get  "provision"
        post "clone"
        post "template_image"
        put "update_template_details"
        get 'load_revision_data'
        post 'update_generic'
      end
    end

    resources :accounts do
      member do
        get "profile"
        get "billing"
        get "security"
      end
      collection do
        post "register_card"
        get "get_cards"
        get "get_invoice_report"
        get "refetch_iam_adapters"
        get "generate_service_reports"
        get "download_service_report"
        post "favorite_report_notification"
        post "report_notification"
        get "get_saas_subscriptions"
      end
    end

    resources :mira, only: [] do
      collection do
        get :web_host_url
      end
    end

    namespace :admin do
      namespace :api do
        namespace :v2 do

          resources :organisations, only: [:index] do
            post "set_trial_days"
            post "make_permanent"
            post "enable_child"
            post "enable_mira"
            post "enable_realdata_user"
          end
          resources :mira_endpoints, only: [:index] do
            collection do 
              post :bulk_update
            end
          end
        end
      end
    end

    get "/service_advisers/adapter_wise_rightsizing" => "service_advisers#adapter_wise_rightsizing"
    get "/service_advisers/get_right_sized_instances" => "service_advisers#get_right_sized_instances"
    get "service_advisers/get_right_sized_vms" => "service_advisers#get_right_sized_vms"
    get "service_advisers/get_right_sized_sqldbs" => "service_advisers#get_right_sized_sqldbs"
    get "service_advisers/get_right_sized_vms_formatted_csv" => "service_advisers#get_right_sized_vms_formatted_csv"
    get "service_advisers/get_right_sized_sqldbs_formatted_csv" => "service_advisers#get_right_sized_sqldbs_formatted_csv"
    get "service_advisers/get_formatted_csv" => "service_advisers#get_formatted_csv"
    get "/service_advisers/resizable_resources" => "service_advisers#resizable_resources"
    get "/service_advisers/resizable_resources_for_report" => "service_advisers#resizable_resources_for_report"
    get "/service_advisers/idle_services" => "service_advisers#idle_services"
    get "/service_advisers/cost_efficiency_summary" => "service_advisers#cost_efficiency_summary"
    get "/service_advisers/get_dashboard_summary" => "service_advisers#get_dashboard_summary"
    get "/service_advisers/get_dashboard_summary_for_report" => "service_advisers#get_dashboard_summary_for_report"
    get "/service_advisers/list_service_type_with_count" => "service_advisers#list_service_type_with_count"
    get "/service_advisers/list_service_type_with_detail" => "service_advisers#list_service_type_with_detail"
    post "/service_advisers/remove_services" => "service_advisers#remove_services"
    post "/service_advisers/move_services" => "service_advisers#move_services"
    post "/service_advisers/unallocate_services" => "service_advisers#unallocate_services"
    get  "/service_advisers/get_recommendation_csv" => "service_advisers#get_recommendation_csv"
    get  "/service_advisers/get_service_advisor_recommendations_report_csv" => "service_advisers#get_service_advisor_recommendations_report_csv"
    get  "service_advisers/get_key_values_array" => "service_advisers#get_key_values_array"
    get  "/service_advisers/exclude_ec2_idle_data_from_right_sizing" => "service_advisers#exclude_ec2_idle_data_from_right_sizing"
    post  "/service_advisers/update_service_tag_key" => "service_advisers#update_service_tag_key"
    get  "/service_advisers/get_account_tag_key" => "service_advisers#get_account_tag_key"
    post  "/service_advisers/ignore_service" => "service_advisers#ignore_service"
    get  "/service_advisers/show_ignored_services" => "service_advisers#show_ignored_services"
    get  "/service_advisers/get_ignored_service_details" => "service_advisers#get_ignored_service_details"
    post   "/service_advisers/unignore_service" => "service_advisers#unignore_service"
    get "/service_advisers/tenant_wise_service_adviser_data" => "service_advisers#tenant_wise_service_adviser_data"
    get  "/service_advisers/get_ignored_service_csv" => "service_advisers#get_ignored_service_csv"
    post "/service_advisers/add_service_comment" => "service_advisers#add_service_comment"
    put "/service_advisers/update_service_comment" => "service_advisers#update_service_comment"
    delete "/service_advisers/remove_service_comment" => "service_advisers#remove_service_comment"
    get "/service_advisers/get_right_sized_s3" => "service_advisers#get_right_sized_s3"
    get "/service_advisers/adapter_wise_s3_rightsizing" => "service_advisers#adapter_wise_s3_rightsizing"
    get "service_advisers/get_formatted_csv_s3" => "service_advisers#get_formatted_csv_s3"
    get "/service_advisers/get_right_sized_rds" => "service_advisers#get_right_sized_rds"
    get "/service_advisers/adapter_wise_rds_rightsizing" => "service_advisers#adapter_wise_rds_rightsizing"
    get "service_advisers/get_formatted_csv_rds" => "service_advisers#get_formatted_csv_rds"
    get "/service_advisers/adapter_wise_vm_right_sizing" => "service_advisers#adapter_wise_vm_right_sizing"
    get "/service_advisers/adapter_wise_sqldb_right_sizing" => "service_advisers#adapter_wise_sqldb_right_sizing"
    get "/service_advisers/get_ahub_vms_recommendation" => "service_advisers#get_ahub_vms_recommendation"
    get "/service_advisers/adapter_wise_ahub_vm_recommendation" => "service_advisers#adapter_wise_ahub_vm_recommendation"
    get "service_advisers/get_ahub_vms_recommendation_formatted_csv" => "service_advisers#get_ahub_vms_recommendation_formatted_csv"
    get "service_advisers/get_ahub_sql_db_recommendation" => "service_advisers#get_ahub_sql_db_recommendation"
    get "service_advisers/adapter_wise_ahub_sql_db_recommendation" => "service_advisers#adapter_wise_ahub_sql_db_recommendation"
    get "service_advisers/get_ahub_sql_db_recommendation_formatted_csv" => "service_advisers#get_ahub_sql_db_recommendation_formatted_csv"
    get "/service_advisers/get_azure_resource_groups" => "service_advisers#get_azure_resource_groups"
    
    get 'service_advisers/get_ahub_sql_elastic_pool_recommendation' => 'service_advisers#get_ahub_sql_elastic_pool_recommendation'
    get 'service_advisers/adapter_wise_ahub_sql_elastic_pool_recommendation' => 'service_advisers#adapter_wise_ahub_sql_elastic_pool_recommendation'
    get 'service_advisers/get_ahub_sql_elastic_pool_recommendation_csv' => 'service_advisers#get_ahub_sql_elastic_pool_recommendation_csv'
    get 'service_advisers/search_tag_key_values' => 'service_advisers#search_tag_key_values'
    get 'service_advisers/show_sa_recommendations' => 'service_advisers#show_sa_recommendations'

    get "/adapters" => "adapters#index"
    post "/adapters" => "adapters#create",
      constraints: lambda { |request|
        type = JSON.parse(request.raw_post)["type"]
        type.eql?("Adapters::AWS")|| type.eql?("Adapters::Azure")
      }
    post "/adapters" => "adapters/cloud_resources/net_app#create",
      constraints: lambda { |request|
        type = JSON.parse(request.raw_post)["type"]
        type.eql?("Adapters::NetApp")
      }
    post "/adapters/:id/update" => "adapters#update",
      constraints: lambda { |request|
        type = JSON.parse(request.raw_post)["type"]
        ["Adapters::AWS", "Adapters::Azure", "Adapters::VmWare", "Adapters::GCP"].include?(type)
      }
    post "/adapters/:id/update" => "adapters/cloud_resources/net_app#update",
      constraints: lambda { |request|
        type = JSON.parse(request.raw_post)["type"]
        type.eql?("Adapters::NetApp")
      }
    put "/adapters/:id/destroy" => "adapters#destroy",
      constraints: lambda { |request|
        type = JSON.parse(request.raw_post)["type"]
        type.eql?("Adapters::AWS")|| type.eql?("Adapters::Azure")
      }
    put "/adapters/:id/destroy" => "adapters/cloud_resources/net_app#destroy",
      constraints: lambda { |request|
        type = JSON.parse(request.raw_post)["type"]
        type.eql?("Adapters::NetApp")
      }

    delete 'adapters/sub_report_config/:id', to: 'adapters#sub_report_config'

    resources :adapters, except: [:delete] do
      member do
        put 'destroy'
        post 'refetch_buckets'
        put 'update_bucket_id'
        get 'add_init_consent'
        get 'aws_account_tag_keys'
        get 'azure_subscription_tag_keys'
        get 'azure_subscription_detail'
      end
      collection do
        get  "select"
        post "select"
        get  "directory"
        get  "list"
        post "verify_bucket"
        post 'destroy_all_adapters'
        post "get_report_names"
        post "get_azure_exports_list"
        post "create_report_config_on_aws"
        post "get_subscriptions_list"
        post "get_scope_item_list"
        post "get_storage_accounts"
        post "create_export_on_azure"
        post "credential_verifier"
        get 'billing_adapters'
        get 'normal_adapters'
        post 'new_account_adapters'
        post 'validate_adapter_limit'
        get 'get_custom_data'
        get 'event_custom_data'
        get 'fetch_subaccounts'
        get 'get_customer_ids'
        post 'create_groups'
        post 'csp_oauth2_callback'
        get 'get_account_tags'
        get 'get_subscription_tags'
        get 'get_normal_adapter_account_tags'
        get 'get_billing_adapter_account_tags'
        get 'fetch_vcenters'
        get 'azure_office365_services'
      end
    end

    resources :organisations, only: [:index] do
      member do
        get 'active_users'
        get 'user_roles'
        get 'organisation_deactive'

      end
      collection do
        post "invite"
        get 'get_org_user_details'
        put 'update_saml_user_details'
        get "users"
        get 'users_with_permission'
      end
    end
    resources :organisations do
      member do
        delete 'delete_invited_user'
        get 'features'
      end
    end
    resources :tenants do
      member do
        put "set_current_tenant"
      end
      collection do
        get 'tenants_list'
        get 'available_tenants'
        post 'assign_tenants'
        put  'update_tenant_permission'
        put 'remove_tenants'
        post 'tenant_resource_groups'
        get 'get_currency'
        get 'assigned_users'
        get 'current_tenant_users'
      end
    end

    get  "get_sso_config"               => "sso_configs#get_sso_config"
    post "create_or_update_sso_config"  => "sso_configs#create_or_update"

    namespace :filer_volumes do
      namespace :cloud_resources do
        resources :net_app do
          member do
            post 'link_to_environment'
            post 'unlink_from_environment'
            post 'mount'
            post 'unmount'
          end
          collection do
            post 'create'
            get 'list_linked_volumes'
          end
        end
      end
    end

    namespace :filers do
      namespace :cloud_resources do
        resources :net_app do
          collection do
            post 'synchronize_filers', as: :synchronize
            get 'filter_based_on_vpc'
          end
          member do
            post 'enable_filer'
          end
        end
      end
    end

    namespace :filer_configurations do
      namespace :cloud_resources do
        resources :net_app do
          collection do
            post 'update_config'
          end
          member do
            post 'destroy_config'
          end
        end
      end
    end

    namespace :storage_vms do
      namespace :cloud_resources do
        resources :net_app do
          collection do
            post 'index'
          end
          member do
            put 'update'
          end
        end
      end
    end

    resources :environments do
      member do
        get  "download_keys", as: :download_private_key
        get  "run_recipes"
        post "provision"
        get  "provision_log"
        get  "shutdown"
        post "deploy"
        get  "start"
        post "start"
        get  "stop"
        post "stop"
        post "terminate"
        get  "select_adapter"
        post "select_adapter"
        get  "parent_services"
        post 'templatize'
        post "terminate_services_removed_from_provider"
        post 'update_access'
        post 'restrict'
        post 'reapply_tags'
        post 'remove_from_management'
        put 'reload'
        get 'load_revision_data'
        get 'check_env_status'
        get 'summary'
        get 'snapshots'
        get 'clusters'
      end
      collection do
        get 'active'
        get 'unallocated'
        get 'get_subnets_external_to_environment'
        post 'search_by_tags'
      end
    end

    resources :services do
      collection do
        get  "select"
        post "select"
        get  "directory"
        get  "environment_parent_services"
        get  "environment_children_services"
        get  "environment_network_services"
        post 'add_existing_services_to_environment'
        get 'search_service'
      end

      member do
        put  "execute"
        get  "start"
        post "start"
        get  "stop"
        post "stop"
        get  "terminate"
        post "terminate"
        get  "reboot"
        post "reboot"
        post "detach"
        post "attach"
        post "reload_service"
        get 'show_service_specific'
        post 'update_service_tags'
        post 'update_overridable_tags'
        post 'delete_service_tag'
        post 'unlink'
        put 'update_service_name'
        post 'perform_iam_instance_association'
        # post ':action', constraints: lambda { |request|
        #   # White-list action name whose basic behavior matches the action,
        #   ['perform_iam_instance_association'].include?(request.path_parameters[:action])
        # }
      end
    end

    get 'sg_replace/get_logs'
    post 'sg_replace/replace' => 'sg_replace#replace'

    resources :soe_scripts, only: [:index, :edit] do
      collection do
        post 'destroy_all_scripts'
        get 'right_size_script'
      end
    end

    # Don't know why resources :groups is inside in resources :remote_sources
    # because in groups controllers remote_sources_id not used anywhere
    # We may need to refactore this
    namespace :soe_scripts do
      resources :remote_sources, only: [:index, :create, :update] do
        member do
          post "destroy"
        end
        collection do
          get "download_sample", constraints: lambda { |req| req.format == :json }
          post "synchronize"
          resources :groups, only: [:index]
        end
        resources :groups, only: [:index, :create, :update, :edit] do
          member do
            post "destroy"
            post "copy"
          end
        end

      end
    end

    resources :resources do
      collection do
        get  "select"
        post "select"
      end
    end

    resources :regions, only: [:index] do
      collection do
        get 'list_all'
        put "enable_disable_region"
      end
    end

    resources :security_groups, only: [:show, :create] do
      member do
        put 'delete_security_group'
        put 'authorize_port_range_inbound'
        put 'revoke_port_range_inbound'
        put 'authorize_port_range_outbound'
        put 'revoke_port_range_outbound'
        # put 'update_name'
      end
    end

    resources :load_balancers, only: [] do
      member do
        post 'attach_subnets'
        post 'apply_security_groups'
        post 'register_instances'
      end
    end

    resources :route_tables, only: [:show] do
      member do
        put 'create_route'
        put 'delete_route'
        put 'associate_route_table'
        put 'disassociate_route_table'
      end
    end

    resources :tasks, only: [:index, :create] do
      member do
        post 'update'
        get 'run_task_now'
      end
      collection do
        post 'update_resize_instances'
        post 'remove'
        get 'all_tasks'
        get 'all_resize_instances_data'
        get 'get_opts_out_service_tags'
        get 'overview_data'
        get 'task_log_data'
        post 'event_pause_resume'
        get 'get_opts_out_adapters'
        get 'get_opts_out_regions'
        get 'get_opts_out_service_types'
        get 'get_opts_out_resource_groups'
        get 'azure_resource_groups'
      end
    end

    resources :subnets, only: [:show] do
      member do
        put 'create_subnet'
        put 'delete_subnet'
        put 'edit_subnet'
      end
    end

    resources :user_roles do
      member do
        get  'members'
        get  'available_users'
        get 'get_user_saml_settings'
        post 'update_saml_settings'
        get  'get_access_rights'
        post "remove_member/:user_id" => 'user_roles#remove_member'
        post 'add_member'
        post 'destroy'
      end
      collection do
        get 'tenant_user_roles'
        get 'user_roles_in_organisation'
      end
    end

    resources :key_pairs do
      collection do
        get 'list_all'
        post  'create'
        post 'destroy'
      end
      member do
        post 'download_keys'
      end
    end

    resources :service_managers do
      collection do
        get 'compute'
        get 'database'
        get 'list_key_pair'
        post 'create_key_pair'
        post 'destroy_key_pair'
        get 'snapshots'
        get 'storages'
        post 'create_s3_bucket'
        post 'delete_s3_bucket'
        get 'refetch_all_buckets'
        post 'share_storage_with_environment'
        post 'update_bucket_acl'
        get 'encryption_keys'
        get 'sync_encryption_keys'
        get 'get_system_log'
        post 'metric_search'
        get 'get_bucket_acl'
        post 'create_snapshots'
        get 'get_service_manager_tags'
        get 'get_azure_service_manager_tags'
        get 'get_instance_types'
        post 'create_service_tags_on_provider'
        get 'get_cost_report_service_details'
        get 'ec2_instance_details'
        get 'get_vmware_service_manager_tags'
        get 'get_gcp_service_manager_tags'
        get 'get_vm_ware_tag_keys'
        get 'get_vm_ware_tag_values'
        get 'get_service_manager_summary_count'
        get 'build_service_manager_csv'
        get 'download_report'
        get 'get_avs_tag_keys'
      end
      member do
        post 'stop'
        get 'terminate'
        post 'reboot'
        post 'start'
        put 'archive'
      end
    end

    resources :access_rights, only: [:index] do
      collection do
        get 'get_user_access_rights'
      end
    end

    resources :account_regions, only: [:index]
    resources :vpcs do
      member do
        get 'default_route_table'
        post 'archive_vpc'
        post 'retry_vpc'
        post 'update_access'
        post 'reload_vpc'
        get 'network_services'
        get 'edit'
      end
      collection do
        # post "create_in_cloudstreet"
        # post "create_on_provider"
        post "check_vpc_presence"
        # get "check_synchronization" ,:sync_vpc
      end
    end

    namespace :costs do
      post 'cost_by_service'
    end

    resources :cost_summaries, only: [:index] do
      collection do
        get "total_cost_by_environment"
      end
    end

    post "costs" => "costs#index"
    resources :snapshots, only: [:index, :create] do
      member do
        post 'launch'
        put 'archive'
        put 'update_name'
      end

      collection do
        get 'get_naming_convention'
      end
    end

    resources :applications do
      member do
        post 'destroy',as: :delete
        post 'add_environments',as: :add_environments
        post 'remove_environments',as: :remove_environments
        post 'reorder_environments',as: :reorder_environments
      end
      collection do
        get 'applications_list'
      end
    end

    resources :rds_configurations do
      member  do
      end
      collection do
        get 'get_rds_data'
      end
    end

    resources :nacls, only: [] do
      member do
        put 'add_inbound_rule'
        put 'add_outbound_rule'
        put 'remove_inbound_rule'
        put 'remove_outbound_rule'
      end
    end

    resources :cost_data, only: [:index] do
      collection do
        get "top_five_environments"
        get "get_daily_data"
        get "get_monthly_data"
        get "get_cost_by_adapter"
        get "get_cost_by_service"
        get "get_charts_data"
        get "get_dashboard_charts_data"
        get "env_and_tmp_state_count"
      end
    end

    resources :machine_image_configurations, only: [:create, :update, :edit] do
      member do
        get "list_soe_run_scripts"
        put 'destroy'
      end
      collection do
        get 'list_templated'
      end
    end

    resources :invoices do
      member do
        get "download_invoice"
      end
    end

    resources :storages do
      collection do
        post "create_s3_bucket"
        post "delete_s3_bucket"
        get "refetch_all_buckets"
        post "share_with_environment"
        post "release_from_environment"
        get "get_bucket_acl"
        post "update_bucket_acl"
      end
    end


    resources :machine_images, only: [:show]
    resources :organisation_images, only: [:show,:create] do
      member do
        get 'verify_compatibility'
        post 'update'
      end
    end

    resources :ami_config_categories, only: [:index, :create] do
      member do
        put "destroy"
      end
      collection do
        post "update"
      end
    end

    resources :security_scan_storages, only: [:index] do
      collection do
        post 'scan'
        post 'scan_environment'
        get 'get_scan_summery'
        post 'get_scan_summery_csv'
        get 'get_scan_summery_by_region'
        get 'get_scan_service_tags'
        post 'get_scan_result'
        get 'unallocated'
        get 'get_notifications'
        post 'create_notification'
        post 'delete_notification'
        post 'get_scan_rules'
        get 'get_tags_for_rules'
        post 'get_services_by_rules'
        get 'get_security_scan_threat_logs'
      end
    end

    resources :azure_security_adviser, only: [:index] do
      collection do
        post 'scan'
        get 'get_scan_summery', to: 'azure_security_adviser#scan_summery'
        post 'get_scan_summery_csv', to: 'azure_security_adviser#scan_summery_csv'
        post 'get_scan_result', to: 'azure_security_adviser#scan_result'
        post 'threat_by_rules'
        post 'services_by_rules'
      end
    end

    resources :service_groups do
      collection do
        get 'adapter_groups'
        get 'tag_groups'
        get 'tag_keys_list'
        post 'sync_adapters_group'
        get 'get_groups_custom_data'
        get 'get_adapters_group_status'
        get 'billing_adapter_groups'
        get 'groups_account_tag_key_values'
        put 'update_group_data_in_athena'
        put 'reload_groups'
        post 'get_groups_info_for_recommendation_policy'
        get 'get_custom_data_tag_keys'
        get 'get_custom_data_tag_values'
        get 'refactor_index'
      end
      member do
        delete 'delete_service_group'
        get 'group_info'
      end
    end
    resources :export_report_mail, only: [:create]
    resources :gcp_account_multi_regions, only: [:index] do
      collection do
        put 'enable_disable'
      end
    end


    # API end points for Swagger Doc Start
    namespace :api do
      namespace :v2 do
        post 'aws/get_cost_usage_reports' => 'aws#get_cost_usage_reports'
        post 'azure/get_export_configurations' => 'azure#get_export_configurations'
        namespace :aws do
          post '/verify_credential' => 'adapters#verify_credential'
          resources :adapters, only: [:index, :destroy] do
            collection do
              post :create_normal
              post :create_backup
              post :create_billing
              delete :delete_all
              post :create_normal_key_based, to: 'adapters#create_normal'
              post :create_normal_role_based, to: 'adapters#create_normal'
              post :create_backup_key_based, to: 'adapters#create_backup'
              post :create_backup_role_based, to: 'adapters#create_backup'
              post :create_billing_key_based, to: 'adapters#create_billing'
              post :create_billing_role_based, to: 'adapters#create_billing'
            end
            member do
              put :update_normal
              put :update_backup
              put :update_billing
              delete :remove
              put :update_normal_key_based, to: 'adapters#update_normal'
              put :update_normal_role_based, to: 'adapters#update_normal'
              put :update_backup_key_based, to: 'adapters#update_backup'
              post :create_backup_role_based, to: 'adapters#update_backup'
              put :update_billing_key_based, to: 'adapters#update_billing'
              put :update_billing_role_based, to: 'adapters#update_billing'
            end
          end

          resources :security_scan_storages, only: [] do
            collection do
              get 'get_scan_summary_by_service_types'
              get 'get_tags_for_rules'
              post 'get_scan_summary_by_rules'
              post 'get_scan_result'
            end
          end
          resources :service_advisers, only: [] do
            collection do
              get 'get_key_values_array'
              get 'list_service_type_with_detail'
              get 'list_service_type_with_count'
              post 'show_ignored_services'
              get 'get_right_sized_instances'
            end
          end
          namespace :service_manager do
            resources :auto_scaling_groups, only: [:index]
            # resources :clusters, only: [:index]
            resources :elastic_ips, only: [:index]
            resources :encryption_keys, only: [:index] do
              collection do
                get :sync_encryption_keys
              end
            end
            resources :eks, only: [:index]
            resources :key_pairs, only: [:index]
            resources :launch_configurations, only: [:index]
            resources :load_balancers, only: [:index]
            resources :network_interfaces, only: [:index]
            resources :databases, only: [:index]
            resources :servers, only: [:index]
            resources :storages, only: [:index]
            resources :volumes, only: [:index]
          end
          resources :service_groups do
            collection do
              post :create_or_update_groups
            end
            member do
              get :initiate_post_activity_worker
            end
          end
          get "/service_groups", to: "service_groups#index"
          post "/service_groups/create_group", to: "service_groups#create"
          put "/service_groups/:id/update_group", to: "service_groups#update"
          delete "/service_groups/:id/remove_service_group", to: "service_groups#destroy"
          get "/service_groups/:id/show", to: "service_groups#show"
        end

        namespace :azure do
          post '/verify_credential' => 'adapters#verify_credential'
          resources :adapters, only: [:index] do
            collection do
              post :create_normal
              post :create_billing
              post :create_normal_adapter, to: 'adapters#create_normal'
              post :create_billing_adapter, to: 'adapters#create_billing'
              delete :delete_all
              get :azure_office365_services
            end
            member do
              put :update_normal
              put :update_billing
              put :update_normal_adapter, to: 'adapters#update_normal'
              put :update_billing_adapter, to: 'adapters#update_billing'
              delete :remove
              get :customer_ids
            end
          end
          resources :service_advisers, only: [] do
            collection do
              get 'tenant_wise_service_adviser_data'
              get 'list_service_type_with_count'
              get 'list_service_type_with_detail'
              get 'get_azure_resource_groups'
              get 'get_right_sized_vms'
              get 'show_ignored_services'
              get 'get_key_values_array'

            end
          end
          resources :security_scan_storages, only: [] do
            collection do
              post 'scan'
              get 'get_scan_summary_by_service_types', to: 'security_scan_storages#get_scan_summary_by_service_types'
              post 'get_scan_summary_csv', to: 'security_scan_storages#scan_summary_csv'
              post 'get_scan_result', to: 'security_scan_storages#get_scan_result'
              post 'get_scan_summary_by_rules'
              post 'services_by_rules'
            end
          end
          namespace :service_manager do
            resources :availability_sets, only: [:index]
            resources :disks, only: [:index]
            resources :load_balancers, only: [:index]
            resources :maria_db, only: [:index]
            resources :my_sql, only: [:index]
            resources :network_interfaces, only: [:index]
            resources :postgre_sql, only: [:index]
            resources :public_ips, only: [:index]
            resources :route_tables, only: [:index]
            resources :security_groups, only: [:index]
            resources :snapshots, only: [:index]
            resources :sql_databases, only: [:index]
            resources :sql_servers, only: [:index]
            resources :storage_accounts, only: [:index]
            resources :subnets, only: [:index]
            resources :virtual_machines, only: [:index]
            resources :virtual_networks, only: [:index]
            resources :elastic_pool, only: [:index]
            resources :blob, only: [:index]
            resources :aks, only: [:index]
            resources :app_services, only: [:index]
            resources :app_service_plans, only: [:index]
          end
          resources :service_groups do
            collection do
              get :custom_data
              post :create_or_update_groups
            end
            member do
              get :initiate_post_activity_worker
            end
          end
          get "/service_groups", to: "service_groups#index"
          get "/service_groups/:id/show", to: "service_groups#show"
          post "/service_groups/create_group", to: "service_groups#create"
          put "/service_groups/:id/update_group", to: "service_groups#update"
          delete "/service_groups/:id/remove_service_group", to: "service_groups#destroy"
        end

        namespace :gcp do
          post '/verify_credential' => 'adapters#verify_credential'
          resources :adapters, only: [:index] do
            collection do
              post :create_normal
              post :create_billing
              post :create_normal_adapter, to: 'adapters#create_normal'
              post :create_billing_adapter, to: 'adapters#create_billing'
              delete :delete_all
            end
            member do
              put :update_normal
              put :update_billing
              put :update_normal_adapter, to: 'adapters#update_normal'
              put :update_billing_adapter, to: 'adapters#update_billing'
              delete :remove
            end
          end
          resources :service_advisers, only: [] do
            collection do
              get 'list_service_type_with_count'
              get 'list_service_type_with_detail'
              get 'get_key_values_array'
            end
          end
          namespace :service_manager do
            resources :disks, only: [:index]
            resources :snapshots, only: [:index]
            resources :virtual_machines, only: [:index]
            resources :images, only: [:index]
          end

          resources :service_groups do
            collection do
              get :custom_data
            end
          end
        end

        namespace :vm_ware do
          get "/adapters" => "adapters#index"
          post "/adapters/create" => "adapters#create"
          put "/adapters/:id/update" => "adapters#update"
          delete "/adapters/:id/remove" => "adapters#remove"
          delete 'adapters/delete_all' => 'adapters#delete_all'
          resource :adapters, only: []
          namespace :service_manager do
            resources :disks, only: [:index]
            resources :virtual_machines, only: [:index]
          end
          resources :service_groups
        end

        resources :signup, to: 'private/users#create', only: [:create]
        resources :report_profiles, only: :index
        post "/report_profiles/create" => "report_profiles#create"
        put "/report_profiles/:id/update" => "report_profiles#update"
        get "/report_profiles/show/:id" => "report_profiles#show"
        delete "/report_profiles/:id/remove" => "report_profiles#remove"
        resources :metric_beat, only: [:index] do
          collection do
            post 'get_metric_data'
          end
        end
        resources :adapters, only: [:index]
        resources :applications, only: [:index]
        resources :environments, only: [:index]
        resources :organisation_settings, only: [:index]
        resources :tenants do
          member do 
            get :adapters
            get :users
          end
        end
        get "/tenants" => "tenants#index"
        post "/tenants/create" => "tenants#create"
        put "/tenants/:id/update" => "tenants#update"
        delete "/tenants/:id/remove" => "tenants#remove"
        resources :tenants, only: [] do
        end
        resources :tasks, only: [:index, :destroy] do
          collection do
            get 'overview_data'
          end
        end
        resources :app_access_secrets, only: [:index]
        post "/app_access_secrets/create" => "app_access_secrets#create"
        put "/app_access_secrets/:id/enable_disable" => "app_access_secrets#enable_disable"
        delete "/app_access_secrets/:id/remove" => "app_access_secrets#remove"

        resources :cfn_templates, :path => '/cfn-template', only: [] do
          collection do
            post :scan
          end
        end

        resources :organisations, only: [] do
          member do 
            get :users
          end
        end

        namespace :child_organisation do
          resources :organisations do
            member do
              get :users
              get :deactive
              get :activate
              post :share_adapter
            end
          end
        end

        resources :user_roles, only: [:index] do
          member do
            get  'get_access_rights'
          end
        end

        resources :excel_export do
          collection do
            post :google_auth
            post :report_summary
          end
        end

        resources :adapters, only: [:index]
        resources :cfn_templates, :path => '/cfn-template', only: [] do
          collection do
            post :scan
          end
        end

        namespace :cs_integration do
          resources :account_regions, only: [:index]
          resources :adapters, only: [:index]
          resources :metrics, only: [] do
           collection do
             post :search_info
           end
          end
          resources :service_advisers, only: [] do
            collection do
              get :cost_efficiency_summary
              get :list_service_type_with_count
              get :show_ignored_services
              get :get_recommendation_csv
              get :list_service_type_with_detail
              get :get_key_values_array
              get :get_right_sized_instances
              get :get_formatted_csv
            end
          end

          resources :service_adviser_configurations, only: [:index, :create]
          resources :servers, only:[] do
            collection do
              get :server_potential_savings
              get :azure_server_potential_savings
            end
          end
        end
      end
    end
    # API end points for Swagger Doc End

    namespace :v2 do
      resources :subscriptions, only: [:index] do
        collection do
          get 'refetch_subscriptions'
          post 'enable_disable_subscriptions'
        end
      end

      resources :CS_services, only: [] do
        member do
          get 'describe'
          get 'list_associated_services'
          get 'describe_service_tags'
        end
      end

      resources :tags, only: [:index]

      resources :templates do
        member do
          post "provision"
        end

        collection do
          get '/:vpc_id/unallocated' => 'templates#show_unallocated_template'
          get '/directory_services' => 'templates#directory_services'
          get '/dettached_services' => 'templates#dettached_services'
        end
      end
      get '/list_synced_vpc' => 'service_synchronizations#list_synced_vpc'
      get '/list_synced_vpc_services' => 'service_synchronizations#list_synced_vpc_services'
      get '/subscriptions/subscriptions_wise_regions' => 'subscriptions#subscriptions_wise_regions'

      resources :vpcs, only: [:index, :create] do
        member do
          get 'network_services'
        end
      end

      resources :environments, only: [:index] do
        member do
          get 'get_environment_services'
          get 'get_environment_services_by_type'
          get 'get_environment_children_services'
          post 'start'
          post 'stop'
          post 'terminate'
        end
      end

    end

    #cs-integration
    namespace :api do
      namespace :v1 do

        # Endpoint to recieve VMware metrics data
        scope module: :vw do
          post 'vdc_data' => 'vdcs#upload_data'
          post 'vdc_jobs' => 'vdcs#jobs'
          post 'vdc_event_logs' => 'vdcs#event_logs'
          get 'vdc_verify_connection' => 'vdcs#verify_connection'
          get 'vdc_events' => 'vdcs#events'
          patch 'vdc_event_complete' => 'vdcs#event_complete'
          get 'verify_connection_for_vdc2' => 'vdcs#verify_connection_for_vdc2'
          post 'vcenter_metadata_from_vdc2' => 'vdcs#upload_data_from_vdc2'
        end

        namespace :cs_integration do
          namespace :azure do
            resources :compliance_reports, only:[] do
              collection do
                get :compliance_report_overview
                get :compliance_report_stats
                post :security_trends
              end
            end
          end
          resources :account_regions, only: [:index]
          resources :adapters, only: [:index]
          resources :metrics, only: [] do
           collection do
             post :search_info
           end
          end
          resources :service_advisers, only: [] do
            collection do
              get :cost_efficiency_summary
              get :list_service_type_with_count
              get :show_ignored_services
              get :get_recommendation_csv
              get :list_service_type_with_detail
              get :get_key_values_array
              get :get_right_sized_instances
              get :get_formatted_csv
            end
          end

          resources :service_adviser_configurations, only: [:index, :create]
          resources :servers, only:[] do
            collection do
              get :server_potential_savings
              get :azure_server_potential_savings
            end
          end
          resources :compliance_reports, only:[] do
            collection do
              get :compliance_report_overview
              get :compliance_report_stats
              post :security_trends
            end
          end
        end
      end
    end


    resources :service_adviser_configurations, only: [:index, :update] do
      collection do
        post :service_adviser_configuration
        get :get_service_adviser_configuration
      end
      member do
        put :reset
      end
    end
    resources :compliance_reports, only: [:index, :show] do
      collection do
        get :compliance_report_overview
        get :compliance_report_stats
        post :security_trends
        post :compliance_report_csv
        get :fetch_failed_services
      end
    end

    namespace :azure do
      resources :compliance_scan_storages, only: [:index] do
        collection do
          post :scan
        end
      end
      resources :compliance_reports, only: [:index, :show] do
        collection do
          post :compliance_report_csv
          post :security_trends
          get :compliance_report_stats
          get :fetch_failed_services
        end
      end
    end
    namespace :service_manager do
      namespace :azure do
        resources :resources, only: [:index, :destroy] do
          member do
            put :reload
            put :update_resource_tags
          end
        end
        namespace :resource do
          namespace :network do
            resources :route_tables, only: [:index] do
              member do
                put :create_or_update_route
                put :delete_route
              end
            end
          end
          namespace :compute do
            resources :virtual_machines, only: [:destroy] do
              member do
                put :start
                put :stop
              end
            end
          end
        end
      end

      # Service managaer gcp resources
      namespace :gcp do
        resources :resources, only: [:index]
      end
    end

    namespace :azure do
      resources :resource_groups, only: [:index]
    end

    resources :general_settings do
      collection do
        post 'update_general_setting'
      end
    end

    resources :visualization do
      collection do
        get 'unallocated'
      end
    end

    resources :integrations do
      collection do
        get "supported_modules_list"
        get "teams_supported_modules_list"
        get "delete_all_workspaces"
      end
    end

    namespace :integrations do
      namespace :slack do
        get "redirect_url"
        get "authentication"
        post "conversations_list"
        get "workspaces_list"
        get "workspace_delete"
        get "integrations_list"
        post "create"
        get "show"
        post "update"
        get "destroy"
        post "update_channel_configuration"
        post "events"
        post "reporting"
      end

       namespace :teams do
        get "app_redirection_url"
        get "bot_redirection_url"
        get "teams_authentication"
        get "show"
        post "update_teams_channel_configuration"
        get "workspaces_list"
        get "teams_workspace_delete"
        match "activities",  via: [:get, :post]
      end

      namespace :service_now do
        post "verify"
        post "service_now_authentication"
        get "workspaces_list"
        get "workspace_show"
        post "service_now_workspace_update"
        get "service_now_workspace_delete"
        post "update_service_now_configuration"
        get "show_service_now_configuration"
        get "service_now_supported_modules_list"
      end

    end

    namespace :child_organisation do
      namespace :reseller do
        resources :organisations do
          member do
            get 'deactive'
            get 'activate'
            get 'active_users'
            get 'users_list'
            get 'edit'
          end
          collection do
            get 'available_child_organisation'
          end
        end
        resources :adapters, only: [:update] do
          collection do
            # get 'shared_adapters'
            get 'available_billing_adapters'
            get 'available_adapter_groups'
            get 'available_normal_adapters'
            get 'remove_adapter'
            # post 'update_shared_adapters'
          end
        end
      end

      resources :organisations do
        member do
          get 'deactive'
          get 'activate'
          get 'active_users'
          get 'users_list'
          get 'edit'
        end
        collection do
          get 'available_child_organisation'
        end
      end
      resources :adapters, only: [:update] do
        collection do
          # get 'shared_adapters'
          get 'available_billing_adapters'
          get 'available_adapter_groups'
          get 'available_normal_adapters'
          get 'remove_adapter'
          # post 'update_shared_adapters'
        end
      end
    end

    resources :organisation_brands do
      collection do 
        get 'login_page'
        get 'show_brand'
        get 'reset'
      end
    end

    resources :sa_recommendations, only: [:create, :update, :index, :destroy] do 
      member do
        get 'task_history'
      end
      collection do
        put 'bulk_update'
      end
    end
    resources :service_group_policies do
      member do
        patch 'enable'
        patch 'disable'
      end
    end

    # deadcode: recommendation_task_policies has been replaced by recommendation_policies
    resources :recommendation_task_policies do
      member do
        put 'trigger_autofix'
      end
    end

    resources :recommendation_policies, only: [:create, :index, :show, :destroy] do
      collection do
        get 'dropdown_option'
      end
    end

    match '/.well-known/microsoft-identity-association.json' => "integrations#microsoft_identity_association", via: [:get, :post, :put]
    get 'install/clear_sync_jobs' => 'application#clear_sync_jobs'
    get 'image/:id' => "image#get_image"
    get 'dashboard/statistics'      => "dashboard#statistics"
    # post "organisation/invite_user"  => "organisations#invite"  , as: 'invite_user_path'
    # get "organisation/users"  => "organisations#users"  , as: 'list_users_path'
    post "os/sync_onwed_images" => "machine_images#sync_owned_images"
    get "os/images"       => "machine_images#index"
    get "selected_os/images" => "organisation_images#index"
    post "selected_os/remove/:id"  => "organisation_images#remove"  , as: 'remove_selected_image'
    get "vpc_list"        => "services#vpc_list"
    get "get_system_log"  => "services#get_system_log"
    get "events"          => "events#index"
    get "events/services" => "events#services"
    get "monitors/search"  => "monitors#search"
    get "metrics"         => "metrics#show"
    post "metrics/search"  => "metrics#search"
    post "metrics/search_info"  => "metrics#search_info"
    get "metrics/typez"   => "metrics#typez"
    get "user"            => "users#current"
    get 'hit_counters'    => "dashboard#hit_counters"
    get 'top_templates'   => "dashboard#top_templates"
    get 'top_environments'=> "dashboard#top_environments"
    get 'top_applications'=> "dashboard#top_applications", as: :top_applications
    get 'list_detailed_services_synchronized_at_cycle' => 'synchronization_logs#list_detailed_services_synchronized_at_cycle'
    get 'list_vpcs_synchronized_at_cycle' => 'synchronization_logs#list_vpcs_synchronized_at_cycle'
    get 'list_vpcs_to_be_synced' => 'service_synchronizations#list_vpcs_to_be_synced'
    get 'list_vpc_and_dependent_services' => 'service_synchronizations#list_vpc_and_dependent_services'
    get '/templates/:vpc_id/:adapter_id/get_security_threats' => 'templates#get_security_threats'
    get '/templates/:vpc_id/unallocated' => 'templates#show_unallocated_template'
    get '/templates/:vpc_id/unallocated_undrawable_services' => 'templates#show_unallocated_template_undrawable_services'
    get '/templates/:vpc_id/unallocated_services_tags' => 'templates#show_unallocated_template_services_tags'
    post '/templates/:vpc_id/create_services_tags_on_provider' => 'templates#create_services_tags_on_provider'
    post '/security_scan_storages/:vpc_id/create_services_tags_on_provider' => 'security_scan_storages#create_services_tags_on_provider'
    get 'list_unattached_volumes_to_be_synced' => 'service_synchronizations#list_unattached_volumes_to_be_synced', as: :list_unattached_volumes_to_be_synced
    get 'list_synchronized_services' => 'service_synchronizations#list_synchronized_services', as: :list_synchronized_services
    get 'synchronize_non_connected_services' => 'service_synchronizations#synchronize_non_connected_services'
    get 'list_synced_service_adapters' => 'service_synchronizations#list_synced_service_adapters'
    post 'copy_service_to_cloudstreet' => 'service_synchronizations#copy_service_to_cloudstreet', as: :copy_service_to_cloudstreet
    post 'copy_vpc_to_cloudstreet' => 'service_synchronizations#copy_vpc_to_cloudstreet'
    get 'list_detached_services' => 'service_synchronizations#list_detached_services'
    post 'add_services_to_environment' => 'service_syncv2hronizations#add_services_to_environment'
    post 'remove_services_and_snapshots' => 'services#remove_services_and_snapshots'
    post 'unallocate_services' => 'services#unallocate_services'
    get 'service_advisor_logs' => 'service_synchronizations#service_advisor_logs'
    get "global_data" => 'accounts#global_data'
    get "dashboard_global_data" => 'accounts#dashboard_global_data'
    get "error_adapters_detail" => 'accounts#error_adapters_detail'


    #Reserved Instance and planner

    get 'instance_planners/reserved_instances_planner' => 'instance_planners#reserved_instances_planner'
    post 'instance_planners/generate_instance_planner_report' => 'instance_planners#generate_instance_planner_report'

    get 'check_access_to_instance' => 'instance_access#check_access_to_instance'
    # get "service_naming_defaults" => 'pdf#show'

    post 'saas_subscription' => 'application#saas_subscription'
    get 'saas_subscription' => 'application#get_saas_subscription'
    root to: "application#root", via: [:get, :post, :patch, :put, :delete, :options]


    # Catch-all
    match "*path", to: "application#routing_error", via: [:get, :post, :patch, :put, :delete, :options]

  end
end
