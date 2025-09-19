# frozen_string_literal: true

# Model to store TagNames
class TagName

  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  store_in client: -> { CurrentAccount.client_db }

end
