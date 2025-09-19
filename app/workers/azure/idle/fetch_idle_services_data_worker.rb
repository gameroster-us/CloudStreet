class Azure::Idle::FetchIdleServicesDataWorker

  include Sidekiq::Worker
  sidekiq_options queue: :azure_idle_queue, backtrace: true
  SERVICES_FOR_IDLE_SERVICES = %w[
    Azure::Resource::Compute::VirtualMachine
    Azure::Resource::Database::MySQL::Server
    Azure::Resource::Database::MariaDB::Server
    Azure::Resource::Database::PostgreSQL::Server
    Azure::Resource::Database::SQL::DB
    Azure::Resource::Compute::Disk
    Azure::Resource::Network::LoadBalancer
    Azure::Resource::Database::SQL::ElasticPool
    Azure::Resource::Blob
    Azure::Resource::Web::AppServicePlan
    Azure::Resource::Container::AKS
  ].freeze

  def perform(options)
    CSLogger.info "starting Idle Worker"
    batch.jobs do
      SERVICES_FOR_IDLE_SERVICES.each do |service_klass|
        idle_service_for = service_klass.split('::')
        idle_service_for = idle_service_for.include?('Database') ? 'DBServer' : idle_service_for.last
        options.merge!({ service_klass: service_klass, idle_service_for: idle_service_for })
        if options["queue_name"].present? 
          ('Azure::Idle::' + idle_service_for + 'IdleWorker').constantize.set(queue: "background_azure_idle_queue").perform_async(options.clone)
        else
          ('Azure::Idle::' + idle_service_for + 'IdleWorker').constantize.perform_async(options.clone)
        end
      end
    end
  rescue StandardError => e
    CSLogger.error e.message
    CSLogger.error e.backtrace
  end

end
