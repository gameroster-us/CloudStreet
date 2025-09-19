module Synchronizers::Azure::Resource::Blob
  def fetch_provider_services(adapter, storage_ac)
    response = adapter.azure_storage_account(adapter.subscription_id).list_blob_services(storage_ac)
    response = response.with_blob_formatter(Azure::RemoteResourceObject::Blob, storage_ac)
    response.in_hash.on_success do |provider_data|
      return provider_data
    end

    response.on_error do |error_code, error_message, data|
      CSLogger.error "#{error_code} : #{error_message}"
      return []
    end
  end

  def sync(adapter, enabled_region_map, storage_account)
    CSLogger.info "Started sync blob for account ---#{storage_account.name}"
    remote_objects = fetch_provider_services(adapter, storage_account)
    remote_objects = remote_objects.is_a?(Array) ? remote_objects : [remote_objects] 
    deactive_deleted_blobs(adapter.id,remote_objects.map(&:provider_id),storage_account)
    return if remote_objects.blank?
    existing_resources = get_existing_resources(adapter, storage_account)
    builder_params = {
      adapter_id: adapter.id,
      resource_group_id: storage_account.resource_group.id,
      enabled_region_map: enabled_region_map,
      remote_objects: remote_objects,
      existing_resources: existing_resources,
      resource_klass: to_s
    }
    resources = Azure::Resource::Builder.call(builder_params)
    resources.each do |r|
      r.cost_by_hour = (storage_account.data.dig("storage_sub_account_costs", 'blob') || 0)
      r.data.merge!(::Azure::Resource::USAGE_COST_KEY => r.cost_by_hour * 24 * 30)
    end

    Azure::Resource::Importer.call(resources)
    remote_objects
  end

  def deactive_deleted_blobs(adapter_id, provider_ids, storage_account)
    resources = self.where("adapter_id =? and region_id =? and data ->>'storage_account_name' =?", adapter_id, storage_account.region_id, storage_account.name).active
    if provider_ids.present?
      resources = resources.where.not(provider_id: provider_ids) 
    end
    resources.update_all(state: :deleted)
  end

  def get_existing_resources(adapter, storage_account)
    self.where("adapter_id =? and azure_resource_group_id =? and data ->>'storage_account_name' =?", adapter.id, storage_account.resource_group.id, storage_account.name).active.group_by(&:provider_id)
  end
end
