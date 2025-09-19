class Validators::EnvironmentValidator < Validator
  attr_reader :services, :interfaces, :connections

  # parent_obj is either environment or template
  def initialize(parent_obj, account, options={})
    super

    if (parent_obj.kind_of?(Template) || parent_obj.kind_of?(Environment))
      @validating_obj, @services, @interfaces, @connections = Environments::EnvironmentBuilder.get_services_from_template parent_obj, account
    end
  end

  def validate
    super services
  end
end
