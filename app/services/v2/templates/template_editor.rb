class V2::Templates::TemplateEditor < CloudStreetService
  
  def self.get_template_services(template_id, user, &block)
  	template = Template.joins(:template_CS_services).eager_load(CS_services: [:template_CS_service, :associated_services, :azure_cost_summary]).where(template_CS_services: {template_id: template_id}).first
  	status TemplateStatus, :success, template, &block
  end

end