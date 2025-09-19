module AdapterInfoRepresenter
  include Roar::JSON
  include Roar::Hypermedia
  include Roar::JSON::HAL

  property :id
  property :name
  property :display_name
  property :adapter_type
  property :state
  property :type
  property :aws_bucket_id
  property :aws_bucket_region_id, as: :bucket_region_id
  property :aws_account_id
  property :adapter_purpose
  property :external_id
  property :sts_region
  property :linked_adapter_sts_region
  property :is_us_gov
  property :role_based
  property :role_arn
  property :billing_adapter
  property :is_billing
  property :sync_state
  property :get_preferred_backup_region_id, as: :preferred_backup_region_id
  property :is_backup
  property :is_normal
  property :iam_adapter
  property :cloud_trail_running
  property :report_configuration
  property :gcp_report_configuration
  property :aws_support_discount
  property :invoice_date
  property :enable_invoice_date
  property :service_types_discount
  property :aws_vat_percentage
  property :export_configuration
  property :role_name
  property :subscription_id
  property :adapter_name_prefix
  property :subscription, extend: SubscriptionRepresenter
  property :azure_account_type
  property :currency
  property :is_shared, getter: -> (args) { args[:options][:current_account].try(:id) != account_id }
  property :is_management_credentials
  property :mgmt_credentials
  property :azure_account_id
  property :get_azure_cloud, as: :azure_cloud
  property :dataset_id
  property :table_name
  property :gcp_access_keys
  property :ea_account_setup
  property :multi_tenant_setup
  property :multiple_tenant_details
  property :gcp_project_id
  property :is_linked_account
  property :get_vmware_data, as: :vmware_sync_data, if: lambda { |args| adapter_type.eql?('VmWare') }
  property :pec_calculation
  property :billing_currencies
  property :rate_card_id
  property :account_setup
  property :init_consent_added
  property :adapter_error
  property :service_tag_key
  property :service_tag_key, if: -> (args) { !is_feature_enabled_for_aws }
  property :service_tag_keys, if: -> (args) { is_feature_enabled_for_aws }
  property :is_group_present_for_serivce_tag_key
  property :margin_discount_calculation
  property :include_office_cost
  property :azure_office_365_services
  property :is_all_azure_office_365_services_selected
  property :get_vcenter_data, as: :vcenters_data, if: lambda { |args| adapter_type.eql?('VmWare') }

  collection(
    :storages,
    class: Storage,
    extend: StorageRepresenter,
    embedded: false,if: lambda { |args| args[:options][:with_buckets].eql?(true) })

  def iam_adapter
      represented.try :is_iam_adapter
  end

  def get_preferred_backup_region_id
    represented.try :preferred_backup_region_id
  end

  def aws_bucket_region_id
    represented.try :bucket_region_id
  end

  def aws_bucket_id
    represented.try :bucket_id
  end

  def adapter_type
    type.to_s.gsub('Adapters::','')
  end

  def is_normal
    represented.adapter_purpose == 'normal' ? true :false
  end

  def is_billing
    represented.adapter_purpose == 'billing' ? true :false
  end

  def is_backup
    represented.adapter_purpose == 'backup' ? true :false
  end

  collection(
      :properties,
      class: Property,
      extend: PropertyRepresenter)

  # link :self do |args|
  #   adapter_path(id) if args[:options][:current_user].can_read?(self)
  # end

  # link :remove do |args|
  #   adapter_path(id) if represented.vpcs_absent && args[:options][:current_user].can_delete?(self)
  # end

  # link :edit do |args|
  #   adapter_path(id) if args[:options][:current_user].can_update?(self)
  # end

  def get_azure_cloud
    represented.try :azure_cloud
  end

  def get_vmware_data
    represented.try(:vmware_sync_data) || {}
  end

  def adapter_error
    represented.try :error_message
  end

  def get_vcenter_data
    represented.try(:vcenters_data) || {}
  end

  def is_feature_enabled_for_aws
    adapter = represented
    return false if !adapter.type.include?('AWS')

    account = Account.find_by(id: adapter.account_id)
    @feature = Flipper.feature($flipper_feature['aws_support_for_cardinality_based_query_feature'].to_sym)
    feature_enabled = account.present? ? @feature.enabled?(account.organisation) : nil
    adapter.type.include?('AWS') && feature_enabled
  end

end
