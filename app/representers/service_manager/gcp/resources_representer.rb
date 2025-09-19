module ServiceManager
  module GCP
    module ResourcesRepresenter
      include Roar::JSON
      include Roar::Hypermedia

      property :total_records, getter: ->(args) { args[:options][:total_records] }
      property :currency, getter: ->(args) { args[:options][:user_options][:current_tenant_currency][0] }
      property :currency_rate, getter: ->(args) { args[:options][:user_options][:current_tenant_currency][1] }

      collection(
        :resources,
        class: GCP::Resource,
        extend: lambda do |args|
            split_service_type = args[:options][:resource_type].split('::')
            representer_type = split_service_type.last
          "ServiceManager::GCP::Resource::#{representer_type}Representer".constantize
        end
      )

      def resources
        collect
      end
    end
  end
end
