module TemplateServicesRepresenter
include Roar::JSON
include Roar::Hypermedia

  collection(
    :services,
    class: TemplateServiceInfo,
    extend: TemplateServiceRepresenter,
    embedded: false)

  # link :self do
  #   { href: "#{services_path(template_id: template_id)}", templated: "true" }
  # end

  def service
    collect
  end
end
