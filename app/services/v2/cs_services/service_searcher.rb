module V2
  module CSServices
    class ServiceSearcher < CloudStreetService
      def self.describe(service_id, service_type, &block)
        begin
          service = "#{service_type}".constantize.find_by_CS_service_id service_id
          tags = ServiceTag.fetch_service_tags(service.CS_service_id)
          status ServiceStatus, :success, {:service => service, :tags => tags}, &block
        rescue Exception => e
          CSLogger.error "V2::CSServices::ServiceSearcher: describe #{e.class} : #{e.message} : #{e.backtrace}"
          status ServiceStatus, :error, service, &block
        ensure
          return service
        end
      end

      def self.list_associated_services(vnet_id, &block)
        result = {}
        begin
          vnet = CSService.find(vnet_id)
          result = CSService.get_all_available_reusable_services_for_azure(vnet)
          status ServiceStatus, :success, result, &block
        rescue Exception => e
          CSLogger.error "V2::CSServices::ServiceSearcher: list_associated_services #{e.class} : #{e.message} : #{e.backtrace}"
          status ServiceStatus, :error, result, &block
        ensure
          return result
        end
      end
    end
  end
end