module Environments
  module Services
    module ServicesRepresenter
      include Roar::JSON
      include Roar::Hypermedia
      NETWORK_SERVICES = %w(AutoScaling  AvailabilityZone ElasticIP InternetGateway LoadBalancer RouteTable SecurityGroup Subnet SubnetGroup )

      property :id
      property :name
      property :type
      property :state
      property :error_message
      property :category
      property :provider_id

      def type
        arr = generic_type.split('::')
        arr[arr.length-1]
      end

      def category
        arr = generic_type.split('::')
        NETWORK_SERVICES.exclude?(generic_type) ? arr[1] : "Compute"
        # arr[1]
      end

      def method_missing(method_name, *args, &block)
        # CSLogger.info "method_name----#{method_name}-#{self.class}--#{self.id}"
        return if self.provider_data.blank?
        return self.provider_data[method_name.to_s] if self.provider_data.is_a?(::Hash)
        #provider_data && ::JSON.parse(provider_data)[method_name.to_s]
        CSLogger.error "Something went wrong................ :("
      end

    end
  end
end
