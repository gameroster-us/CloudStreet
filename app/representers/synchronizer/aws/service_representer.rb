module Synchronizer
  module AWS
    module ServiceRepresenter
    include Roar::JSON
    include Roar::Hypermedia

      property :name
      property :type
      property :generic_type
      property :provider_id
      property :sync_status
      property :get_monthly_cost, as: :monthly_cost #getter: lambda { |*| self.cost_by_hour*24*30}
      property :changes, if: lambda{|args| self.persisted? && self.changed? }
      property :state
      property :data, getter: lambda { |*|
        if self.is_route_table?
          set_formatted_associations
        elsif is_sg?
          self.data["ip_permissions"] = ::ProviderData::Sg::IPPermissions.new(self.data["ip_permissions"]).extended
          self.data["ip_permissions_egress"] = ::ProviderData::Sg::IPPermissions.new(self.data["ip_permissions_egress"]).extended
        elsif is_nacl?
          self.data["inbound"] = self.data["entries"].select{|e| e["egress"]== false}
          self.data["outbound"] = self.data["entries"].select{|e| e["egress"]== true}
        elsif  is_autoscaling_configuration?
          self.data["block_device_mappings"] = self.data["block_device_mappings"].map do |mapping|
            mapping["DeviceName"]
          end if self.data["block_device_mappings"]
        elsif is_server?
          self.data["elastic_ip_list"]
        elsif is_eni?
          self.data["private_ips"] = self.data["private_ips"].collect{|ip|
            if ip["elasticIp"].present?
              if ip["elasticIp"].length==36
                ip["elasticIp"] = Service.find_by_id(ip["elasticIp"]).provider_id
              end
            end
            ip
          }
        end
        self.data
      }

      def get_monthly_cost
        self.cost_by_hour*24*30
      end

      def set_formatted_associations
        subnet_ids = (self.data['associations']||[]).map{ |association| association["subnetId"]}
        return if subnet_ids.blank?
        filters = {
          account_id: self.account_id,
          adapter_id: self.adapter_id,
          region_id: self.region_id,
          provider_id: subnet_ids,
          vpc_id: self.vpc_id
        }
        self.data["associations"] = Service.synced_services.subnets.where(filters).collect{|subnet|
          {
            subnet_id: subnet["provider_id"],
            subnet_name: (subnet.data["tags"] && subnet.data["tags"]["Name"]) ? subnet.data["tags"]["Name"] : subnet.provider_id,
            cidr_block: subnet.data["cidr_block"],
          }
        }

      end

      def sync_status
        if self.persisted?
          if AWSRecord.where({
            provider_id: provider_id,
            account: account,
            adapter: adapter,
            region_id: region_id
          }).present?
            "In both"
          else
            "Only in CloudStreet"
          end
        else
          "Only in AWS"
        end
      end
    end
  end
end
