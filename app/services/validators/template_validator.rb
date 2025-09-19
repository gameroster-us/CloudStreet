class Validators::TemplateValidator < Validator
  attr_reader :services, :interfaces, :connections

  def initialize(attr_map, account, options={})
    super

    @validating_obj, @services, @interfaces, @connections = Templates::TemplateBuilder.build_template_from_params attr_map, account
  end

  def validate
    super services
  end
end
