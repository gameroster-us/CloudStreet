module EnvironmentDisplayRepresenter
  include Roar::JSON
  include Roar::Hypermedia

  property :id
  property :name
  property :template_id
  property :position
  property :state
  property :created_by, exec_context: :decorator 
  property :created_at, getter: lambda { |*| created_at.strftime CommonConstants::DEFAULT_TIME_FORMATE }
  property :updated_by, exec_context: :decorator 
  property :updated_at, getter: lambda { |*| updated_at.strftime CommonConstants::DEFAULT_TIME_FORMATE }
  property :adapter_type, exec_context: :decorator
  property :adapter_name, exec_context: :decorator
  property :region_name, exec_context: :decorator
  property :application_map, exec_context: :decorator
  property :errors, getter: lambda { |*| 
    self.errored_services.collect do |service|
    {
      provider_id: service.provider_id, 
      name: service.name, 
      state: service.state, 
      error_message: service.error_message
    }
    end
  }
  property :user_role_ids

  property :restricted, getter: lambda{|args| data && data['restricted']}

  property :restriction, getter: lambda { |args| check_permission(args[:options][:current_user]) }


  property :current_month_charges, if: lambda { |opts| opts[:options][:cost_options] && opts[:options][:cost_options].include?(:current_month_charges) }
  property :current_month_estimate, if: lambda { |opts| opts[:options][:cost_options] && opts[:options][:cost_options].include?(:current_month_estimate) }
  property :description
  property :vpc_state

  def check_permission(user)
    return unless user
    restriction_applied = (user.user_roles.pluck(:id) & user_role_ids) rescue []
    (restriction_applied ==[]) && (data && data['restricted'])
  end

  # link :show do |args|
  #   CSLogger.info "args ------#{args}"
  #   environment_path(self) if args[:current_user].can_read?(self)
  # end

  def application_map
    app = represented.application
    app.present? ? { id: app.id, name: app.name } : {}
  end

  def created_by
    represented.creator.try :name
  end

  def updated_by
    represented.updator.try :name
  end

  def adapter_type
    represented.default_adapter.try :provider_name
  end

  def adapter_name
    represented.default_adapter.try :name
  end

  def region_name
    represented.region.try :region_name
  end

  def current_month_estimate
    represented.get_current_month_estimate.round(3)
  end

  def current_month_charges
    represented.get_current_month_charges.round(3)
  end

  def vpc_state
    represented.vpcs.first.state rescue "NA"
  end
end
