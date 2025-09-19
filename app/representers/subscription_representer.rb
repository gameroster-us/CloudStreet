module SubscriptionRepresenter
include Roar::JSON
include Roar::Hypermedia
  
  property :id
  property :subscription_id
  property :display_name
  property :subscription_policies
  property :state
  property :offer_id

end