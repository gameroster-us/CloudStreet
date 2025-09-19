# frozen_string_literal: true

# Contain all accountIDs for adapters
class GCPProjectIds
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  store_in client: -> { CurrentAccount.client_db }
end
