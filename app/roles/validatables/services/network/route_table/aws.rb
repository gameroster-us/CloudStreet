module Validatables::Services::Network::RouteTable::AWS
  def perform_validations(params)
    ig_or_instance_id = params.has_key?("instance_id") ? params[:instance_id] : params[:internet_gateway_id]
    validate_route(params, ig_or_instance_id)
  end

  # {"route_table_id"=>"rtb-7f07931a", "destination_cidr_block"=>"0.0.0.0/0", "internet_gateway_id"=>"igw-5e6ecd3b"}
  def validate_route(params, ig_or_instance_id = nil)
    ig_or_instance_id = ig_or_instance_id.nil? ? params[:internet_gateway_id] : ig_or_instance_id
    validate_format_of_internet_gateway_id(ig_or_instance_id)
    validate_format_of_destination_cidr_block(params[:destination_cidr_block])
    validate_cidr_block_conflict_with_local(params[:destination_cidr_block], self.cidr_of_local_route)
    validate_cidr_block_conflict_with_other_route(params[:destination_cidr_block], self.cidrs_in_routes)
  end

  private

  def validate_format_of_internet_gateway_id(input_id)
    unless input_id[0..1] == 'i-' || input_id[0..3] == 'igw-'
      self.errors.add(:route_table_id, 'Target must be Internet Gateway ID or Instance ID')
    end
    self.errors.add(:route_table_id, 'Target must be Internet Gateway ID or Instance ID') if input_id.size < 3
  end

  def validate_format_of_destination_cidr_block(cidr_block)
    parsed_cidr ||= NetAddr::CIDRv4.create(cidr_block) rescue nil
    if parsed_cidr.blank?
      self.errors.add(:destination_cidr_block, 'Destination must be a valid CIDR')
    end
  end

  def validate_cidr_block_conflict_with_local(new_cidr_block, existing_cidr)
    new_cidr_block = NetAddr::CIDRv4.create(new_cidr_block) rescue nil
    return if new_cidr_block.blank? || existing_cidr.blank?
    existing_cidr = NetAddr::CIDRv4.create(existing_cidr)
    compare_result = new_cidr_block.cmp(existing_cidr)
    if (compare_result == (-1) || compare_result == 0)
      self.errors.add(:destination_cidr_block, "Destination CIDR must be less specific than #{existing_cidr.to_s}")
    end
  end

  def validate_cidr_block_conflict_with_other_route(new_cidr_block, existing_cidrs_arr)
    new_cidr_block = NetAddr::CIDRv4.create(new_cidr_block) rescue nil
    return if new_cidr_block.blank?
    cidr_conflict_found = existing_cidrs_arr.any? do |cidr|
      next if cidr.blank?
      cidr = NetAddr::CIDRv4.create(cidr)
      new_cidr_block.cmp(cidr) == 0
    end
    if cidr_conflict_found
      self.errors.add(:destination_cidr_block, "Destination CIDR is already specified #{new_cidr_block.to_s}")
    end
  end
end
