require 'open-uri'
class Images::ImageUpdator < CloudStreetService
  class << self
    def update_on_environment(environment_id, user, template_id=nil)
      begin
        template = Template.find(template_id) if template_id
        image_of = template_id ? 'templates' : 'environments'
        service_id = template_id ? template_id : environment_id
        services = template_id ? template.services_for_image(user) : nil
        ::ImageService.save_image(service_id, image_of, user, services)
      rescue Exception => e
      	CSLogger.error e.message
      	CSLogger.error e.class
      	CSLogger.error e.backtrace
      end	
    end
  end
end