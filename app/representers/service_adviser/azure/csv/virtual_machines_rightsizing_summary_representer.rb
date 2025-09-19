module ServiceAdviser::Azure::Csv::VirtualMachinesRightsizingSummaryRepresenter
  include Roar::JSON
  include Roar::Hypermedia

  collection(
    :virtual_machines_rightsizings,
    class: Azure::Rightsizing,
    extend: ::ServiceAdviser::Azure::Csv::VirtualMachinesRightsizingRepresenter,
    embedded: true
  )

  property :meta_data, getter: ->(args) { args[:options][:total_records][:meta_data] }
  property :currency, getter: ->(args) { args[:options][:user_options][:currency_code]}

  def virtual_machines_rightsizings
    collect
  end
end
