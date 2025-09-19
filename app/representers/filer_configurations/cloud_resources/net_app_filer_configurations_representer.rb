module FilerConfigurations
  module CloudResources
    module NetAppFilerConfigurationsRepresenter
include Roar::JSON
include Roar::Hypermedia

      property :total_records, getter: lambda { |args| args[:options][:total_records]}

      collection(
        :net_app_filer_configurations,
        class: FilerConfigurations::CloudResources::NetApp,
        extend: FilerConfigurations::CloudResources::NetAppFilerConfigurationRepresenter
        )

      def net_app_filer_configurations
        collect
      end
    end
  end
end