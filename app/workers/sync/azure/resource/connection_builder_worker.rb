class Sync::Azure::Resource::ConnectionBuilderWorker
  include Sidekiq::Worker
  sidekiq_options queue: :azure_sync, :retry => false, backtrace: true

  def perform(adapter_id, resource_group_id, enabled_region_ids)
    adapter = Adapter.find_by(id: adapter_id)
    resource_group = Azure::ResourceGroup.find_by(id: resource_group_id)
    return if adapter.blank? || resource_group.blank?
    connections = Synchronizers::Azure::SYNC_RESOURCES.each_with_object([]) do |klass, memo|
      res = klass.constantize.try(:get_primary_connections, adapter_id, resource_group_id, enabled_region_ids)
      memo.concat(res) if res.present? && res.is_a?(Array)
    end

    Azure::ResourceConnection.import connections if connections.present?
  rescue StandardError => e
    CSLogger.error e.message
    CSLogger.error e.backtrace
  end

end
