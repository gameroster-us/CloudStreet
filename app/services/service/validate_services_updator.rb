class Service::ValidateServicesUpdator < CloudStreetService
  def self.build_services_from_params(params, template, account)
    services    = []
    interfaces  = []
    connections = []

    params[:services].each do |s|
      klass = ActionController::Base.helpers.sanitize(s[:type])
      type = klass.safe_constantize rescue ''

      service_params = {
        geometry: s[:geometry],
        account_id: account.id,
        name: s[:name],
        vpc_id: s[:vpc_id],
        region_id: params[:region_id],
        adapter_id: params[:adapter_id]
      }

      service = type.find_by(id: s[:id])

      if service.nil?
        directory_service = Service.find_by(type: s[:type], state: :directory)
        service = directory_service.dup
        service.id = s[:id]
      end

      service.update!(service_params.reject{ |k,v| v.blank? })

      s[:properties].each do |property|
        service.send("#{property[:name]}=".to_sym, property[:value])
      end if s[:properties]

      service.template! if (!service.template? && !service.removed_from_provider?)

      service.save!

      template.services << service if template.services.where(id: s[:id]).empty?
      services << service # return this
    end if params[:services]

    # Interfaces
    params[:services].each do |s|
      klass = ActionController::Base.helpers.sanitize(s[:type])
      type = klass.safe_constantize rescue ''
      service = type.where(id: s[:id], account_id: params[:account_id]).first

      s[:interfaces].each do |i|
        interface_params = {
          name: i[:name],
          depends: i[:depends],
          interface_type: i[:interface_type],
          service: service
        }

        interface = service.interfaces.where(id: i[:id]).first_or_create

        interface.update!(interface_params)
        interface.save!
        interfaces << interface # return this
      end unless s[:interfaces].nil? || s[:interfaces].empty?
    end if params[:services]

    # # Connections
    params[:services].each do |s|
      klass = ActionController::Base.helpers.sanitize(s[:type])
      type = klass.safe_constantize rescue ''
      service = type.where(id: s[:id], account_id: params[:account_id]).first

      s[:interfaces].each do |i|

        if i[:depends]
          interface = service.interfaces.where(id: i[:id]).first
          interface.connections.destroy_all
          i[:connections].each do |c|
            remote_interface = Interface.where(id: c[:remote_interface_id]).first

            relation = Connection.where(id: c[:id]).create
            relation.interface = interface
            relation.remote_interface = remote_interface

            interface.connections << relation
            connections << relation # return this
          end if i[:connections]
        end
      end if s[:interfaces]
    end if params[:services]

    template.save!

    # Remove deleted objects
    delete_services(params, template)
    delete_interfaces(params, template)

    services    = template.services
    interfaces  = services.map { |s| s.interfaces.to_a }.flatten.uniq
    connections = interfaces.map { |i| i.connections.to_a }.flatten.uniq
    [services, interfaces, connections]
  end

  def self.delete_interfaces(params, template)
    interface_ids = params[:services].map { |s| s[:interfaces].map { |i| i[:id] } unless s[:interfaces].nil? || s[:interfaces].empty? }
    interface_ids.flatten!
    template.services.each do |service|
      interfaces = service.interfaces.where.not(id: interface_ids)

      interfaces.each do |interface|
        interface.connections.each { |c| c.destroy }
        Connection.where(remote_interface_id: interface.id).each { |c| c.destroy }
        interface.destroy
      end
    end
  end

  def self.delete_services(params, template)
    service_ids = params[:services].map { |x| x[:id] }
    CSLogger.info service_ids.inspect
    services = template.services.where.not(id: service_ids)

    services.each do |service|
      service.interfaces.each do |interface|
        interface.connections.each { |connection| connection.destroy }
        Connection.where(remote_interface_id: interface.id).each { |c| c.destroy }
      end
    end
    services.each do |service|
      service.interfaces.destroy_all
    end
    services.each do |service|
      template.services.delete(service)
      service.template_service.destroy if service.template_service.present?
      TemplateService.where(service_id: service.id).destroy_all
      service.destroy
    end
  end
end
