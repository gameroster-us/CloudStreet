class VwVcenterService < CloudStreetService
  class << self
    def fetch_vcenters(current_account, current_tenant, params, &block)
      vw_vcenter_ids = tenant_level_vw_vcenter_through_billing(current_tenant, params[:billing_adapter_id])
      vw_vcenters_data = []
      if vw_vcenter_ids.any?
        vw_vcenter_ids.each do |vw_vcenter_id|
          vw_vcenter = VwVcenter.find vw_vcenter_id
          vw_vcenters_data << { id: vw_vcenter.id, name: vw_vcenter.provider_name } if vw_vcenter
        end
      end
      status Status, :success, vw_vcenters_data, &block
    rescue Exception => e
      status Status, :error, e.message, &block
    end

    def tenant_level_vw_vcenter_through_billing(tenant, billing_adapter_id)
      # Checking adapter group is shared within tenant
      # This will also check if adapter is created within tenant 
      if tenant.is_default
        Adapters::VmWare.fetch_vw_vcenter_ids_through_billing(billing_adapter_id)
      else
        # # Checking is group shared within tenant with same billing adapter
        # # group might be two type partial OR All Selected
        # two_cases_groups = tenant.service_groups.where(billing_adapter_id: billing_adapter_id) # Share group only
        # ServiceGroup.vcenterids_from_service_group(two_cases_groups.ids)

        two_cases_groups = tenant.service_groups.where(billing_adapter_id: billing_adapter_id, provider_type: 'VmWare') # shared adapters and own tenant adapter
        if two_cases_groups.exists?
          ServiceGroup.vcenterids_from_service_group(two_cases_groups.ids).flatten.uniq
        else
          if tenant.adapters.vm_ware_adapter.report_status_true.ids.include?(billing_adapter_id)
            Adapters::VmWare.fetch_vw_vcenter_ids_through_billing(billing_adapter_id)
          else
            []
          end
        end
      end
    end
  end
end
