class ProviderWrappers::AWS::TagRemote < ProviderWrappers::AWS

  def create(tags_params)
    CSLogger.info "------agent-------creating new tags ----------------#{agent.class}---"
    begin
      if agent.is_a?(Fog::AWS::ELB::Real)
        agent.add_tags service.provider_id, tag_map_attributes(tags_params)
      elsif agent.is_a?(Fog::AWS::AutoScaling::Real)
        params = tag_map_attributes(tags_params)
        final_tags = params.map do |k, v|
          asg_tags(k, v, service)
        end
        agent.create_or_update_tags final_tags
      elsif agent.is_a?(Fog::AWS::RDS::Real)
        agent.add_tags_to_resource service.provider_id, tag_map_attributes(tags_params)
      else
        agent.create_tags service.provider_id, tag_map_attributes(tags_params)
      end
    rescue => e
      CSLogger.error "#{e.message}"
      service.error_message = e.message
      service.error!
      return service
    end
  end

  def delete(tags_params)
    tag_params = tags_params.blank? ? {} : tags_params
    begin
      CSLogger.info "------agent-----------deleting tags------------#{agent.class}--"
      if agent.is_a?(Fog::AWS::ELB::Real)
        agent.remove_tags service.provider_id, tags_params.keys
      elsif agent.is_a?(Fog::AWS::AutoScaling::Real)
        final_tags = tags_params.map do |k, v|
          asg_tags(k, v, service)
        end
        agent.delete_tags final_tags
      elsif agent.is_a?(Fog::AWS::RDS::Real)
        agent.remove_tags_from_resource service.provider_id, tags_params.keys
      else
        agent.delete_tags service.provider_id, tags_params
      end    
    rescue => e
      return {"error_msg"=>e.message}
    end
  end

  def tag_map_attributes(tags_params)
    return tags_params if tags_params.kind_of?(Hash)
    tag_hash = tags_params.inject(Hash.new([])) { |hash, tag| hash[tag.tag_key] = ((tag.tag_type == "dropdown" && tag.apply_naming_param) ? tag.naming_param : tag.tag_value); hash }
    tag_hash.merge!({"Name" => service.name})# unless agent.is_a?(Fog::AWS::ELB::Real) || agent.is_a?(Fog::AWS::RDS::Real)
    tag_hash = tag_hash.reject {|hash| hash['tag_key'] == "environment_id"} if Service::NEW_TAGGABLE_RESUABLE_SERVICES.include?(service.generic_type.to_s)
    if service.is_server?
      parse_custom_tags(tag_hash)
    else
      parse_normal_tags(tag_hash)
   end
  end

  def parse_custom_tags(env_tags_params)
    env_tags_params.each do |k,v|
      next if v.nil?
      if v && v.include?('$$')
        if v == "$$soeconfiguration"
          soeconfiguration_name = MachineImageConfiguration.find(service.image_config_id).name rescue ''
          env_tags_params[k] = soeconfiguration_name
        elsif v == "$$soename"        
          organisation_image_id = MachineImageConfiguration.find(service.image_config_id).organisation_image_id  rescue ''
          soename = OrganisationImage.find(organisation_image_id).image_name rescue ''
          env_tags_params[k] = soename
        end
      end
    end
    env_tags_params
  end

  def parse_normal_tags(env_tags_params)
    env_tags_params.each do |k,v|
      if v && v.include?('$$')
        if v == "%soeconfiguration%"
          env_tags_params[k] = ""
        elsif v == "%soename%"
          env_tags_params[k] = ""
        end
      end
    end
    CSLogger.info "env_tags_params: #{env_tags_params.inspect}"
    env_tags_params    
  end

  def create_tags(tags_map)
    agent.create_tags service.provider_id, tags_map
  end

  def asg_tags(key, value, asg)
    propagate_at_launch = key != asg.name
    { 'Key' => key, 'PropagateAtLaunch' => propagate_at_launch, 'ResourceId' => asg.provider_id, 'ResourceType' => 'auto-scaling-group', 'Value' => value}
  end

  def delete_tags(tags_map)
    agent.delete_tags service.provider_id, tags_map
  end
end