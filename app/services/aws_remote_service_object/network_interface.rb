module AWSRemoteServiceObject
  class NetworkInterface < Struct.new(:provider_data, :group_set, :attachment, :association, :tag_set, :provider_id, :subnet_id, :vpc_id, :availability_zone, :description, :owner_id, :requester_managed, :status, :mac_address, :private_ip_address, :private_dns_name, :source_dest_check, :private_ip_addresses)

    def get_attributes_for_service_table
      attributes = { primary: false }
      attributes.merge!({
                          instance_id: self.attachment["instanceId"],
                          primary: self.attachment["deviceIndex"].eql?("0")
      }) unless self.attachment.empty?

      attributes.merge!({
                          name: self.tag_set["Name"]||self.provider_id,
                          tags: self.tag_set,
                          description: self.description,
                          status: self.status,
                          subnet_id: self.subnet_id,
                          provider_vpc_id: self.vpc_id,
                          availablity_zone: self.availability_zone,
                          security_groups: self.group_set,
                          mac_address: self.mac_address,
                          private_ips: self.parsed_private_ip_addresses,
                          source_dest_check: self.source_dest_check,
                          private_dns_name: self.private_dns_name,
                          interface_association: self.association,
                          attachment: self.attachment,
                          state: "running",
                          provider_id: self.provider_id,
                          provider_data: self.provider_data,
                          vpc_id: self.vpc_id,
                          service_tags: Services::ServiceHelpers::AWS.get_service_tags(self.tag_set)
      })
    end

    def parsed_private_ip_addresses
      self.private_ip_addresses.collect do |private_ip_address|
        if private_ip_address["association"] && private_ip_address["association"]["associationId"]
          private_ip_address["item"]      = private_ip_address["association"]["associationId"]
          private_ip_address["elasticIp"]   = private_ip_address["association"]["publicIp"]
          private_ip_address["hasElasticIP"]  = true
        end
        private_ip_address
      end
    end

    def self.parse_from_json(data)
      return self.new(
        data,
        data["group_set"],
        data["attachment"],
        data["association"],
        data["tag_set"],
        data["network_interface_id"],
        data["subnet_id"],
        data["vpc_id"],
        data["availability_zone"],
        data["description"],
        data["owner_id"],
        data["requester_managed"],
        data["status"],
        data["mac_address"],
        data["private_ip_address"],
        data["private_dns_name"],
        data["source_dest_check"],
        data["private_ip_addresses"]
      )
    end
  end
end
