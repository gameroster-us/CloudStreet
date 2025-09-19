class TemplateServiceTagsFetcher < CloudStreetService
  
  def self.fetch_overridden_tags(template, params, &block)
    return status Status, :success, [], &block if template.template_tags.blank?
    overridable_service_tags = template.template_tags.select {|template_tag| !template_tag['overridable_services'].blank?}
    return status Status, :success, [], &block if overridable_service_tags.blank?
    parsed_overridden_tags = []
    
    overridable_service_tags.each do |service_tag_hash|
      next(service_tag_hash) if service_tag_hash['overridable_services'].blank?
      template.services.each do |template_service|
        next(template_service) if !(service_tag_hash['overridable_services'].collect(&:downcase).include?(template_service.generic_type.split('::').last.downcase))
        service_tag_value = get_service_tag_value(template_service, service_tag_hash, template)
        next(template_service) if (service_tag_value == service_tag_hash['tag_value'] && !is_overridable?(template_service, service_tag_hash, template))
        parsed_overridden_tags << {
          service_name: template_service.name,
          service_type: get_service_type(template_service),
          tag_key: service_tag_hash['tag_key'],
          service_tag_value: service_tag_value,
          template_tag_value: service_tag_hash['tag_value']
        }
      end
    end
    status Status, :success, parsed_overridden_tags, &block
  end

  def self.is_overridable?(template_service, service_tag_hash, template)
    return false if template.template_tags.blank?
    is_overridable = template_service.service_tags.select {|service_tag| service_tag['tag_key'] == service_tag_hash['tag_key']} if template_service.service_tags.present?
    if is_overridable.blank?
      return false
    else
      return true if is_overridable.first['is_overridable'] =~ (/^(true|t|yes|y|1)$/i)
      return false if is_overridable.first['is_overridable'].nil? || is_overridable.first['is_overridable'] =~ (/^(false|f|no|n|0)$/i)
    end
  end

  def self.get_service_type(template_service)
    template_service.generic_type.split('::').last.eql?('Rds') ? 'RDS' : template_service.generic_type.split('::').last
  end

  def self.get_service_tag_value(template_service, service_tag_hash, template)
    return nil if template.template_tags.blank?
    tag = template_service.service_tags.select {|service_tag| service_tag['tag_key'] == service_tag_hash['tag_key']} if template_service && template_service.service_tags.present?
    if tag.blank?
      return nil
    else
      tag.first['tag_value']
    end
  end
end