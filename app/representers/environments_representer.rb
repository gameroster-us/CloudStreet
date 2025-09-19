module EnvironmentsRepresenter
  include Roar::JSON
  include Roar::Hypermedia
  include Roar::JSON::HAL

  collection(
    :environment,
    class: Environment,
    extend: EnvironmentRepresenter,
    embedded: true)

  link :self do
    environments_path
  end

  link :make do |args|
    environments_path if args[:options][:current_user].can_create?(Environment, { account_id: args[:options][:current_account].id })
  end

  def environment
    collect
  end
end
