class ServiceGroup::CostUpdaterService
  attr_accessor :service_group, :tenant
  
  # AWS_CURRENT_MONTH_HSH = { "unblended" => 0.0, "net_amortized_cost" => 0.0, "customer_cost" => 0.0, "net_cost" => 0.0 }
  # AZURE_CURRENT_MONTH_HSH = { "cost" => 0.0,  "customer_cost" => 0.0, "net_cost" => 0.0, "net_cost(r)" => 0.0}
  # GCP_CURRENT_MONTH_HSH = {}
  # VMWARE_CURRENT_MONTH_HSH = {}
  ALL_PROVIDER_HSH = { :unblended => 0.0, :net_amortized_cost => 0.0, :customer_cost => 0.0, :net_cost => 0.0, :reseller_org_net_cost => 0.0, :amortized => 0.0, :cost => 0.0 }

  def initialize(args)
    @service_group = args[:service_group]
    @tenant = args[:tenant]
  end

  def call()
    CSLogger.info "---- ServiceGroupCost call method started  for ServiceGroup Id: #{service_group.id} | Tenant Id: #{tenant.id} | name:  #{service_group.name} ----"
    attr = { :service_group_name => service_group.name, :provider_type => service_group.provider_type, :billing_adapter_id => service_group.billing_adapter_id }
    current_tenant_id = tenant.id
    having_normal_adapters = service_group.provider_type.eql?('VmWare') ? service_group.vcenter_ids.blank? : service_group.normal_adapter_ids.blank?
    
    if service_group.is_group_empty? && having_normal_adapters
      attr.merge!({ :service_adviser_pf => 0.0, :ri_pf => 0.0, :sp_pf => 0.0 })
    else
      normal_adapter_ids = service_group.list_normal_adapter_ids
      billing_adapter_id = service_group.billing_adapter_id
      provider_type = service_group.provider_type
      vcenter_ids = service_group.vcenter_ids if provider_type.eql?('VmWare')

      # Service Calling for potential benefit and ri and sp pf
      all_pf_hash = ServiceGroup::AllAdaptersCostUpdater.get_ri_sp_potential_benfit_data(normal_adapter_ids, provider_type, current_tenant_id)
      # AWS RI we need to check tenant does not have own aws billing_adapter_id then we making ri_pf cost 0.0
      if provider_type.eql?('AWS')
        all_pf_hash[:ri_pf] = 0.0 unless has_aws_own_billing
      end
      attr.merge!(all_pf_hash)
      # Service Calling for last 30 days cost
      # last_30_days = ServiceGroup::AllAdaptersCostUpdater.last_30_days_cost(billing_adapter_id, normal_adapter_ids, provider_type, {vcenter_ids: vcenter_ids})
      # attr.merge!(:last_30_days_currency => last_30_days.first || 'USD', :last_30_days => last_30_days.last || 0.0)
    end

    # saving
    CSLogger.info "Service Group Cost attributes #{attr}================"
    sgc = ServiceGroupCost.find_or_initialize_by({ 'service_group_id' => service_group.id, 'tenant_id' => current_tenant_id })
    sgc.attributes = attr
    sgc.current_month_spend = ALL_PROVIDER_HSH unless sgc.persisted? # if record is new we are saving default hash either it save whatever previosuly data
    sgc.save

    CSLogger.info "------- ServiceGroupCost call method Completed ==============#{sgc.inspect}=========== for ServiceGroup Id: #{service_group.id} | name: #{service_group.name} -----"
  rescue StandardError => e
    CSLogger.info "!!!!! Unable to save service groups cost for | Name: #{service_group.name} | Id: #{service_group.id} !!!!"
    CSLogger.info "Message | #{e.message}"
    CSLogger.info "Bactrace | #{e.backtrace}"
  end

  def has_aws_own_billing
    account_id = tenant&.organisation&.account.try(:id)
    # checking parent organisation of default and subtenant
    if tenant.organisation.parent_id.nil?
      tenant.adapters.aws_adapter.billing_adapters.where(id: service_group.billing_adapter_id).exists?
    else
      # checking reseller and child organsiation of default and subtenant
      tenant.adapters.aws_adapter.billing_adapters.where(id: service_group.billing_adapter_id, account_id: account_id).exists?
    end
  end
end