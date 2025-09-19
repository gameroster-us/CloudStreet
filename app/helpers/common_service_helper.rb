module CommonServiceHelper
  # Return tenant_adapter_ids if no adapter or group filter is present
  # Return array of adapter_ids from adapter filter OR group filter
  # Return array of combined 'adapter_ids' and 'adapter_ids from group' if both
  # Both parameters are present, otherwise return empty array
  def adapter_ids_from_filter(tenant, provider, adapter_id, group_id)
    adapter_id  = nil if ['all', ''].include?(adapter_id)
    group_id    = nil if [''].include?(group_id)
    type        = AdapterSearcher::PROVIDER_TYPE_MAP[provider.try(:downcase)]
    tenant_adapter_ids = tenant.adapters.where(type: type)
                                        .normal_adapters
                                        .available
                                        .ids

    return tenant_adapter_ids if adapter_id.blank? && group_id.blank?

    adapter_ids = Array[* adapter_id]
    adapter_ids_from_group = ServiceGroup.adapterids_from_adapter_group(group_id)
    (tenant_adapter_ids & (adapter_ids + adapter_ids_from_group)).uniq # Recheck available tenant adapters and return
  end
end