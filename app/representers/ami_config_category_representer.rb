module AmiConfigCategoryRepresenter
include Roar::JSON
include Roar::Hypermedia

  property :id
  property :name
  property :account_id
  property :errors, getter: lambda { |*| self.errors.present? }
  property :error_messages, if: lambda{ |*| self.errors.present? }, getter: lambda { |*| self.errors.messages }
end
