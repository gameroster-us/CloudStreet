module ServicesRepresenter
  include Roar::JSON
  include Roar::Hypermedia
  include Roar::JSON::HAL

  collection(
    :service,
    class: Service,
    extend: ServiceRepresenter,
    embedded: true)

  link :self do
    { href: "#{services_path}", templated: "true" }
  end

  link :directory do
    { href: "#{directory_services_path}{?id,type,version}", templated: "true" }
  end

  link :make do |args|
    { href: "#{services_path}", templated: "true" } if args[:options][:current_user].can_create?(Service, { account_id: args[:options][:current_account].id })
  end

  def service
    collect
  end
end
