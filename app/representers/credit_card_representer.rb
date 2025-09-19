module CreditCardRepresenter
include Roar::JSON
include Roar::Hypermedia

  property :card_number
  property :card_holder
  property :card_expiry
  property :card_type

  def card_type
  	response_data['card_type'] 	
  end
end