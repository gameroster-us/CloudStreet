module GlobalAdmin::OrganisationsRepresenter

  include Roar::JSON
  include Roar::Hypermedia
  include Roar::JSON::HAL

  property :total_records

  collection(
    :organisations,
    class: Organisation,
    extend: GlobalAdmin::OrganisationRepresenter,
    embedded: true
  )

  def organisations
    self[:organisations].collect
  end

  def total_records
    self[:total_records]
  end

end