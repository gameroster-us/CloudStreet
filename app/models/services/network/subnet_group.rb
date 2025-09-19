class Services::Network::SubnetGroup < Service
  store_accessor :data, :description
  # def container
  #   true
  # end

  def protocol
    "Protocols::SubnetGroup"
  end

  def provides
    [
      { name: "subnet", protocol: Protocols::SubnetGroup }
    ]
  end

  def depends
    [
      # { name: "gateway", protocol: Protocols::IP }
    ]
  end

  def properties
    [
      {
        name: "description",
        title: "Description",
        value: description || 'Subnet Group Description',
        form_options: {
          type: "text"
        },
        validation: '/^[a-zA-Z0-9-\s]*$/'
      }
    ]
  end

  def startup
    provision
  end

  def provision
  end

  def create_service_interfaces(params)
    sg_ids = params[:subnet_ids]
    
    vpc_id = params[:vpc_id]
    return unless vpc_id.present?

    vpc = self.environment.services.vpcs.where(id: vpc_id).first
    Interface.find_or_create_interfaces(self, vpc) if vpc
    
    if sg_ids.present?
      subnets = self.environment.services.subnets.where(id: sg_ids)
      subnets.each do |subnet|
        Interface.find_or_create_interfaces(self, subnet)
      end
    end
    
  end
end
