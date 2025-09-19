module TeamsUserRepresenter
  include Roar::JSON
  include Roar::Hypermedia
  property :id
  property :user_id
  property :account_id
  property :organisation_id
  property :user_details
end