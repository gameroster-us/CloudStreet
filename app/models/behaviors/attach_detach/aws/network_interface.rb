module Behaviors
	module AttachDetach
		module AWS
			module NetworkInterface

			  ATTACHABLE_SERVICES = ["Services::Network::ElasticIP::AWS"]
				
			  def attach_elastic_ip(eip, options)
			    return false if eip.association_id.blank? || eip.provider_data["network_interface_id"].blank? || !eip.provider_data["network_interface_id"].eql?(self.provider_id)
			    attached_server = self.attached_server
			    private_ip_to_attach = eip.provider_data["private_ip_address"].blank? ? self.private_ips.detect { |ip| ip["primary"].eql?("true") }["privateIpAddress"] : eip.provider_data["private_ip_address"]
			    self.private_ips.each do |private_ip|
			      next unless private_ip_to_attach.eql?(private_ip["privateIpAddress"])
			      if private_ip["association"].present? && !private_ip["association"]["associationId"].eql?(eip.association_id)
			      	attached_server.detach_service!(eip.type, {provider_id: private_ip["association"]["publicIp"], private_ip: private_ip}) unless attached_server.blank?
			      	old_eip = ::Services::Network::ElasticIP::AWS.find_by_adapter_id_and_provider_id(self.adapter_id,private_ip["association"]["publicIp"])
			      	old_eip.mark_as_detached! unless old_eip.blank?
			      end
			      private_ip["item"] = eip.association_id
			      private_ip["elasticIp"] = eip.id
			      private_ip["hasElasticIP"] = true
			      private_ip["association"] = {
			        "publicIp"=> eip.provider_id, 
			        "publicDnsName"=> eip.get_public_dns, 
			        "ipOwnerId"=> eip.provider_data["ip_owner_id"], 
			        "associationId"=> eip.association_id
			      }
			      self.provider_data["association"] = self.interface_association =  private_ip["association"] if private_ip["primary"].eql?("true")
			      attached_server.attach_service!(eip, {private_ip: private_ip}) unless attached_server.blank?
			    end
			    self.provider_data["private_ip_addresses"] = self.private_ips
			    return true
			  end

			  def detach_elastic_ip(options)
			    return false if options[:association_id].blank?
			    attached_server = self.attached_server
			    self.private_ips.each do |private_ip|
			      if private_ip["item"].eql?(options[:association_id]) || (private_ip["association"] && private_ip["association"]["associationId"].eql?(options[:association_id]))
			        attached_server.detach_service!("Services::Network::ElasticIP::AWS", {provider_id: private_ip["association"]["publicIp"], private_ip: private_ip}) unless attached_server.blank?
			        private_ip["item"] = "true"
			        private_ip.delete("elasticIp")
			        private_ip.delete("hasElasticIP")
			        private_ip.delete("association")
			        self.interface_association = self.provider_data["association"] = {} if private_ip["primary"].eql?("true")
			      end
			    end
			    self.provider_data["private_ip_addresses"] = self.private_ips
			    return true
			  end

			  def mark_as_detached
			  	self.provider_data["attachment"] = self.attachment = {}
			  	self.provider_data["status"] = self.status = "available"
			  end


			  def attached_elastic_ips
			  	elastic_ip_ids = interfaces.of_type("Protocols::ElasticIP").first.try(:remote_interfaces).map(&:service_id)
			  	return [] if elastic_ip_ids.blank?
			  	::Services::Network::ElasticIP::AWS.includes(:environment).where(id: elastic_ip_ids)
			  end

			  def attached_server
			  	return if self.attachment["instanceId"].blank?
			  	::Services::Compute::Server::AWS.includes(:environment).where(provider_id: self.attachment["instanceId"], adapter_id: self.adapter_id, region_id: self.region_id, account_id: self.account_id).first
			  end

			end
		end
	end
end