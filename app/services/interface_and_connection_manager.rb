module InterfaceAndConnectionManager

	def initialize_default_interfaces(service_type, service_id, service_name)
		service_klass = service_type.constantize
		service_klass::INTERFACES.inject([]) { |interface_objs, klass| 
			interface_objs << Interface.new(
				id: SecureRandom.uuid,
				depends: true,
				interface_type: klass.protocol,
				name: service_name,
				service_id: service_id
				) 
			}.push(
				Interface.new(
					id: SecureRandom.uuid,
					depends: false,
					interface_type: service_klass.protocol,
					name: service_name,
					service_id: service_id
				)
			)
	end



	class ConnectionUpdator
		include InterfaceAndConnectionManager

		def initialize(adapter_id,region_id,service_map = {})
			@adapter_id 			= adapter_id
			@region_id  			= region_id
			@service_map 			= service_map
			@services 				= []
			@removed_connections 	= []
			@new_connections 		= []
		end

		def process
			@service_map.each do |environment_id, service_ids|
				grouped_modefied_services = environment_id.blank? ?  find_unallocated_services(service_ids) : find_environmented_services(environment_id, service_ids)
				services = environment_id.blank? ?  find_unallocated_services : find_environmented_services(environment_id)
				grouped_modefied_services.each do |vpc_id, modefied_services|
					@services = services[vpc_id] && services[vpc_id].group_by(&:type)
					modefied_services.each do |modified_service|
						remote_protocol_id_map = modified_service.class::INTERFACES.each_with_object({}) { |interface_klass, remote_protocol_id_map| (remote_protocol_id_map[interface_klass::protocol] ||=[]).concat(find_connections(modified_service,interface_klass.to_s)) }
						@new_connections += update_connections(modified_service, remote_protocol_id_map)
					end
				end
			end
			return @new_connections, @removed_connections
		end

		def find_connections(service, interface_klass)
			(@services[interface_klass] || []).collect { |possible_dependent_service|
				begin
					if service.connected_to(possible_dependent_service, @services)
						create_default_interfaces(possible_dependent_service) unless possible_dependent_service.reload.interfaces.exists?
						possible_dependent_service.find_interface(possible_dependent_service.protocol).id
					elsif ((service.type.eql? 'Services::Network::LoadBalancer::AWS') && (possible_dependent_service.class.name.eql? 'Services::Compute::Server::AWS') && service.provider_data['instances'].include?(possible_dependent_service.data['instance_id']))
						create_default_interfaces(possible_dependent_service) unless possible_dependent_service.reload.interfaces.exists?
						possible_dependent_service.find_interface(possible_dependent_service.protocol).id
					else
						nil
					end
				rescue Exception => e
					CSLogger.error e.message
					CSLogger.error e.backtrace
					nil
				end
			}.compact
		end

		def update_connections(modified_service,remote_protocol_id_map)
			modified_service = create_default_interfaces(modified_service) unless modified_service.reload.interfaces.exists?
			all_own_interface_ids   = modified_service.interfaces.map(&:id)
			all_remote_interace_ids = remote_protocol_id_map.values.flatten
			# Fixed N+1 query
			connection_res = Connection.where(interface_id: all_own_interface_ids).to_a
            existing_remote_interface_res, removed_connections_res = connection_res.partition {|iter| all_remote_interace_ids.include? iter['remote_interface_id']}
			existing_remote_interface_ids = existing_remote_interface_res.pluck('remote_interface_id')
			@removed_connections += removed_connections_res.pluck('id')
			new_connections = []
			remote_protocol_id_map.each do |interface_protocol, remote_interface_ids|
				own_interface_id = modified_service.find_interface(interface_protocol).try(:id)
				own_interface_id = create_missing_interface(interface_protocol,modified_service).id if own_interface_id.blank?
				(remote_interface_ids- existing_remote_interface_ids).each do |remote_interface_id|
					new_connections << Connection.new(interface_id: own_interface_id, remote_interface_id: remote_interface_id, internal: false)
				end
			end
			return new_connections
		end

		private

		def find_environmented_services(environment_id,service_ids = [])
			filters = {adapter_id: @adapter_id, region_id: @region_id, environment_services: {environment_id: environment_id}}
			filters.merge!({id: service_ids}) unless service_ids.blank?
			Service.includes(:environment_service,:interfaces).where(filters).active_services.select("services.id,services.name,provider_id,type,provider_data,data,state,vpc_id").group_by { |s| find_vpc_id(s) }
		end

		def find_unallocated_services(service_ids = [])
			filters = {adapter_id: @adapter_id, region_id: @region_id}
			filters.merge!({id: service_ids}) unless service_ids.blank?
			Service.includes(:interfaces).where(filters).synced_services.select("services.id,name,provider_id,type,provider_data,data,state,vpc_id").group_by { |s| find_vpc_id(s) }
		end

		def find_vpc_id(service)
			if ["Services::Vpc","Services::Database::Rds::AWS"].include?(service.type)
				service[:vpc_id] || find_vpc_id_from_base_table(service)
			else
				service.vpc_id
			end
		end

		def find_vpc_id_from_base_table(service)
			Vpcs::AWS.find_by(vpc_id: service.provider_id, adapter_id: @adapter_id, region_id: @region_id, state: "available").try(:id) if service.type.eql?("Services::Vpc")
		end

		def clear_removed_connections
			Connection.where(id: @removed_connections).delete_all unless @removed_connections.blank?
		end

		def create_new_connections
			Connection.import @new_connections unless @new_connections.blank?
		end

		def create_default_interfaces(service)
			Interface.import initialize_default_interfaces(service.type, service.id, service.name)
			service.reload
			service
		end

		def create_missing_interface(interface_type, service)
			Interface.create(
				id: SecureRandom.uuid,
				depends: true,
				interface_type: interface_type,
				name: service.name,
				service_id: service.id
			)
		end
	end
end
