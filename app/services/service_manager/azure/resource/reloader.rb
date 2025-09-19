class ServiceManager::Azure::Resource::Reloader < CloudStreetService

  class << self

    def call(azure_resource, &block)
      azure_resource.reloading
      Azure::Resource::ReloadWorker.perform_async(azure_resource.id)
      status Status, :success, azure_resource, &block
    rescue StandardError => e
      status Status, :error, e.message, &block
    end

  end

end
