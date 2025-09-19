module Azure
  module Compute
    module VirtualMachineRepresenter
include Roar::JSON
include Roar::Hypermedia
      include AzureServicesRepresenter

      property :operating_system
      property :vm_size
      # property :subnet
      # property :private_ip_address
      # property :public_ip_address
      # property :hardware_profile
      # property :image_reference
      # property :os_disk
      # property :data_disks
      property :network_interfaces
      # property :disks
      property :availability_set
      property :os_profile
      property :publisher
      property :offer
      property :sku
      
      # def private_ip_address
      #   ""
      # end

      def network_interfaces
        interfaces = []
        nics = self.read_attribute("network_interfaces")
        unless nics.blank?
          nics.each do |interface|
            interfaces << Parsers::Azure::ServiceNameParser.parse_network_interface_name(interface)
          end
        end
        interfaces
      end

      # def subnet
      #   # Parsers::Azure::ServiceNameParser.parse_subnet_name(self.data["subnet"])
      # end

      # def public_ip_address
      #   Parsers::Azure::ServiceNameParser.parse_public_ip_address(self.data["public_ip_address"])
      # end

      # def disks
      #   self.data["os_disk"]["disk_type"] = "OS Disk"
      #   self.data["data_disks"].each do |disk|
      #     disk["disk_type"] = "Data Disk"
      #   end
      #   [self.data["os_disk"]] + self.data["data_disks"]
      # end

      def availability_set
        Parsers::Azure::ServiceNameParser.parse_availability_set_name(self.read_attribute("availability_set")) unless self.read_attribute("availability_set").blank?
      end
    end
  end
end  
