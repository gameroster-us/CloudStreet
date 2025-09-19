class Sync::Azure::Resource::FetcherWorker
  include Sidekiq::Worker
  sidekiq_options queue: :azure_sync, :retry => false, backtrace: true

  def perform(klass, adapter_id, resource_group_id, enabled_region_map, **args)
    adapter = Adapter.find_by(id: adapter_id)
    resource_group = Azure::ResourceGroup.find_by(id: resource_group_id)
    return if adapter.blank? || resource_group.blank?

    klass.constantize.sync(adapter, resource_group, enabled_region_map)
  rescue StandardError => e
    CSLogger.error e.message
    CSLogger.info "Debug Info :- class =  #{klass}, adapter_id = #{adapter_id}, resource_group_id = #{resource_group_id}"
    CSLogger.error e.backtrace
  end

end
