class GCPBudget < ApplicationRecord
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  store_in client: -> { CurrentAccount.client_db }
end
