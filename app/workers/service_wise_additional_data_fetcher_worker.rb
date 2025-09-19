class ServiceWiseAdditionalDataFetcherWorker
  include Sidekiq::Worker
  sidekiq_options queue: :sync, retry: false, backtrace: true

  def perform(options)
    template_cost = nil
    adapter = Adapter.find(options['adapter_id'])
    region = Region.find(options['region_id'])
    ::REDIS.with do |conn|
      template_cost = JSON.parse(conn.get("#{region.code}_cost"))
    end
    services = options['service_klass'].constantize.where(adapter_id: adapter.id,region_id: options['region_id'], account_id: adapter.account_id).where.not(provider_id: nil).active_services
    begin
      retries ||= 0
      services.each do |service|
        begin
          extra_attributes = options['service_klass'].constantize.fetch_additional_data_for_sync(service.provider_id, adapter, region.code, {})
          unless extra_attributes.nil?
            service.data = {} if service.data.eql?(nil)
            service.data.merge!(extra_attributes)
            service.update_hourly_cost(template_cost)
            service.check_and_mark_unused if ["Services::Network::LoadBalancer::AWS", "Services::Network::ApplicationLoadBalancer::AWS", "Services::Network::NetworkLoadBalancer::AWS"].include?(service.type)
            service.save
          end
        rescue Fog::AWS::RDS::NotFound, Fog::AWS::ELB::NotFound, Fog::AWS::AutoScaling::ValidationError, Fog::Compute::AWS::NotFound => e
          CSLogger.error "Excon Exeption:: => #{e.message}"
          extra_attributes = {}
        rescue Excon::Error::Socket, Excon::Error::Timeout, Excon::Error::ServiceUnavailable => e
          CSLogger.error "Excon Exeption:: => #{e.message}"
          if (retries += 1) < 3
            sleep 3
            print "."
            retry
          else
            extra_attributes = {}
          end
        rescue Fog::AWS::Compute::Error => e
          CSLogger.error "Fog Gem Error OR Standard Exeption:: => #{e.message}"
          extra_attributes = {}
        rescue Exception, ::Adapters::InvalidAdapterError => e
          extra_attributes = service.set_default_addtional_data
        end
      end
    end
  end
end
