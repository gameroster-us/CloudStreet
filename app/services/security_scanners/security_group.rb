module SecurityScanners::SecurityGroup

 	def start_scanning
 		security_groups = get_security_groups
 		# return if security_groups.blank?
 		default_sg_associated_service_count = get_sg_associated_service_count
 		new_security_groups = []
 		SecurityScanners::ScannerObjects::SecurityGroup.parse(security_groups) do |new_sg|
 			new_sg.associated_service_count = default_sg_associated_service_count[new_sg.group_id] if !default_sg_associated_service_count.blank?  && default_sg_associated_service_count.has_key?(new_sg.group_id)
 			new_security_groups << new_sg
 		end
 		rule_sets = parse_scanning_rule_conditions
 		new_security_groups.each do |security_group|
 			threats = []
 			security_group.scan(rule_sets) do |threat|
 				if threat.present?
 					threats << threat
 				end
 			end
 			prepare_threats_to_import(security_group, threats) if threats.present?
 		end

 		clear_and_update_scan_report
 	end


	def parse_condition(condition)
		operator = SecurityScanner::OPERATOR_MAP[condition[1]]
		if condition[0].is_a?Array
			case condition[1]
		    when 'notEqual'
		      fromP = condition[0][0]||0
		      toP = condition[0][1]||65535
		      "!Range.new(#{fromP},#{toP}).include?(#{condition[2]})"
		    when 'includes','exactRange'
		      fromP = condition[0][0]||0
		      toP = condition[0][1]||65535
		      "Range.new(#{fromP}, #{toP}).include?(#{condition[2]})"
		    when 'containNoneOf'
		      fromP = condition[0][0]||0
		      toP = condition[0][1]||65535
		      "!(#{condition[2]}.any? { |element| (#{fromP}..#{toP}).cover?(element)})"
		    when 'containAtLeastOneOf'
		      fromP = condition[0][0]||0
		      toP = condition[0][1]||65535
		      "(#{condition[2]}.any? { |element| (#{fromP}..#{toP}).cover?(element)})"
		    when 'match'
		      fromP = condition[0][0]||0
		      toP = condition[0][1]||65535
		      "#{fromP}-#{toP}.#{operator}(#{condition[2]})"
		    end
		else
			case condition[1]
			when 'containAtLeastOneOf','includes','containNoneOf'
			 "#{condition[2]}.#{operator}(#{condition[0]})"
			when 'notEmpty'
			 "!#{condition[0]}.#{operator}"
			when 'isBlank?'
		  		"#{condition[0]}.#{operator}"
		    when 'equalTo?'
		  		"#{condition[0]}.#{operator}(#{condition[2]})"
		    when 'equals'
		  		"(#{condition[0]} #{operator} #{condition[2]})"
		  	when 'doMatch?'
                "#{condition[0]}.#{operator}(#{condition[2]})" 	
			else
			 "#{condition[0]} #{operator} #{condition[2]}"
			end
		end
		
	end


	def get_security_groups
		sgs = SecurityGroups::AWS.select("id,provider_data").where(adapter_id: @adapter.id,region_id: @region.id,state: "available")
		sgs = sgs.where(group_id: @provider_ids) unless @provider_ids.blank?
		return sgs.to_a
		# begin
  #         retries ||= 0
  #         connection = @adapter.connection(@region.code)
		#   return @provider_ids.blank? ? connection.security_groups.all : connection.security_groups.all({"group-id" => @provider_ids})
		# rescue Excon::Error::Timeout => e
	 #        if (retries += 1) < 3
	 #          sleep 5
	 #          CSLogger.info "retrying..."
	 #          retry
	 #        end
	 #        CSLogger.info "AWS Timeout detected for getting security groups"
	 #        return
	 #    rescue Exception => e
	 #    	CSLogger.error(e.message)
	 #    	CSLogger.error(e.backtrace)
	 #    	return
  #   	end
	end

	def get_sg_associated_service_count(filter={})
		filter.merge!(adapter_id: @adapter.id) unless @adapter.blank?
		filter.merge!(region_id: @region.id) unless @region.blank?
		filter.merge!(provider_id: @provider_ids) unless @provider_ids.blank?
		running_sg_interface_map = Services::Network::SecurityGroup::AWS.includes(:interfaces).where(filter).where("data->>'default' != ?","true").where(interfaces: {depends: false, interface_type: "Protocols::SecurityGroup"},state: "running").select("services.id,services.adapter_id,services.region_id,services.provider_id,services.state,interfaces.*").inject({}) { |h,sg| h[sg.provider_id] = sg.interfaces.first.id; h }

		interface_wise_service_count_map = Service.joins(interfaces: :connections).where(interfaces: {interface_type: "Protocols::SecurityGroup"},connections: {remote_interface_id: running_sg_interface_map.values}, state: "running").select("services.id,services.state,interfaces.id,interfaces.service_id,interfaces.interface_type,connections.id,connections.interface_id,connections.remote_interface_id").group("connections.remote_interface_id").count("services.id")

		running_sg_interface_map.each do |k,v|
			if interface_wise_service_count_map.has_key?(v)
				running_sg_interface_map[k] = interface_wise_service_count_map[v]
			else
				running_sg_interface_map.delete(k)
			end
		end
		return running_sg_interface_map
	end

	def prepare_threats_to_import(object, threats)
		@common_attributes ||= {account_id: @adapter.account_id, adapter_id: @adapter.id, region_id: @region.id}
		category = SecurityScanner::SERVICE_TYPE_CATEGORY_MAP[@service_type]
		threats.each do |threat|
			@results << @common_attributes.merge({
				provider_id: object.group_id,
				service_name: object.name,
				state: "running",
				service_type: "Services::Network::SecurityGroup::AWS",
				category: category,
				vpc_id: object.vpc_id,
				scan_status: threat['level'],
				scan_details: threat['description'],
				scan_details_desc: threat['description_detail'],
				CS_rule_id: threat["CS_rule_id"],
                rule_type: threat["type"],
				environments: [],
				tags: SecurityScanner.convert_tags(object.tags),
				created_at: Time.now,
				updated_at: Time.now
			})
		end
	end

end
