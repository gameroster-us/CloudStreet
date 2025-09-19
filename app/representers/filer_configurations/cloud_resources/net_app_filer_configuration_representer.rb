module FilerConfigurations
  module CloudResources
    module NetAppFilerConfigurationRepresenter
include Roar::JSON
include Roar::Hypermedia

      property :id
      property :name
      # property :vpc_id
      property :vpc, getter: lambda { |args| self.vpc ||  "" }
      property :account_id
      property :get_adapter_id, as: :adapter_id
      property :security_group, getter: lambda { |args|  self.security_group || "" }
      # property :security_group_name, getter: lambda { |args|  self.security_group.name}
      property :protocol
      property :region_id
      property :filer_id
      property :storage_vm_id

      def get_adapter_id
        self.adapter_id || ""
      end

    end
  end
end