class Validators::Services::Network::RouteTable::AWS < Validators::Services::Network::RouteTable
	def validate_preconditions
    must_have_attribute :name if service_creation_event?
    must_have_attribute :service_vpc_id if service_creation_event?
  end

  def validate_vpc
  	check(:is_valid_vpc?) { I18n.t('validator.error_msgs.services.route_table.invalid_vpc') } if service_creation_event?
  end

  def is_valid_vpc?
  	vpcs = @options[:environment].services.vpcs.pluck :id
  	!vpcs.include?(validating_obj.service_vpc_id)
  end
end