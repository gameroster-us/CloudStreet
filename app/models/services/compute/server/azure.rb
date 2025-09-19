class Services::Compute::Server::Azure < Services::Compute::Server
  include Services::ServiceHelpers::Azure
  store_accessor :data, :vm_user, :password, :vm_size, :cloud_service_name, :vm_name, :subnet_id
  VM_SIZES_LIST = %w(ExtraSmall Small Medium Large ExtraLarge A5 A6 A7 Basic_A0 Basic_A1 Basic_A2 Basic_A3 Basic_A4)

  def startup
    CloudStreet.log "-------------------------------------Creating #{self.class.name} #{self.inspect}"
    if cloud_service_name
      start_virtual_machine
    else
      provision
    end 
  end 

  def start_virtual_machine
    service_actions(:start_virtual_machine)
    Events::Service::Start.create(account: self.account, service: self, user: user, environment: self.environment, revision: environment.revision, username: user.username, component_name: self.name)
  end

  def shutdown 
    service_actions(:shutdown_virtual_machine)
  end

  def reboot_service   
    service_actions(:restart_virtual_machine)
  end

  def terminate_service(params={})
    service_actions(:delete_virtual_machine)  
  end

  def service_actions(method_name)
    CloudStreet.log "-----------------------------------------------Method #{method_name}"
    if cloud_service_name
      begin
        connection_vm.send method_name, vm_name, cloud_service_name
      rescue => e
        CloudStreet.log "Error: #{e.message}"
        raise e
      end
      virtual_machine = find_virtual_machine
      CloudStreet.log "-------------------------------------Remote vm #{virtual_machine.inspect}"
      update_attribute :provider_data, virtual_machine.to_json
    end
    virtual_machine
  end  

  def find_virtual_machine
    connection_vm.get_virtual_machine(name, cloud_service_name)
  end  
  
  def provision
    params = {
      vm_name: name,
      vm_user: vm_user,
      image: 'fb83b3509582419d99629ce476bcb5c8__SQL-Server-2014RTM-12.0.2000.8-Web-ENU-WS2012R2-AprilGA',
      password: password,
      location: environment.region.code
    }
    remote_vpc = parent_remote_vpc
    options = {
      vm_size: vm_size,
      affinity_group_name: remote_vpc.affinity_group,
      virtual_network_name: remote_vpc.name,
      subnet_name: fetch_first_remote_service(Protocols::Subnet).name
    }

    virtual_machine = connection_vm.create_virtual_machine(params, options)
    CloudStreet.log "----------------------------------------------Created #{virtual_machine.inspect}"
    update_attribute :provider_data, virtual_machine.to_json
    update_attribute :cloud_service_name, virtual_machine.cloud_service_name
    update_attribute :vm_name, virtual_machine.vm_name
    update_attribute :subnet_id, fetch_first_remote_service(Protocols::Subnet).id
    update_attribute :service_vpc_id, fetch_first_remote_service(Protocols::Vpc).id
    
    virtual_machine
  end

  def properties
    [
      {
        form_options: {
          type: 'text'
        },
        name: 'vm_user',
        title: 'User',
        value: vm_user || 'username'
      },
      {
        form_options: {
          type: 'text'
        },
        name: 'password',
        title: 'Password',
        value: password || 'Compl@exPassw0rd'
      },
      {
        form_options: {
          type: 'select',
          options: VM_SIZES_LIST
        },
        name: 'vm_size',
        title: 'Size',
        value: vm_size || VM_SIZES_LIST.first
      }
    ]
  end

  def parent_services
    [Services::Vpc, Services::Network::Subnet::Azure]
  end
end
