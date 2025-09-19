# frozen_string_literal: true

# Model to store Tag categories
class TagCategory

  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Athena::VmWare::Extras
  store_in client: -> { CurrentAccount.client_db }

  # has_many :tags, class_name: 'TagNames::VmWare'
  # associations
  has_many :versions, as: :versionable, dependent: :destroy

  field :name
  field :adapter_id
  field :value
  field :created_at, type: DateTime
  field :updated_at, type: DateTime
  field :vcenter_id
  field :column_name
  field :childs, type: Array, default: []
  field :associableTypes, type: Array, default: []

  def col_name
    get_column_new_name(self.name)
  end

  index(adapter_id: 1)
  index(name: 1)
  index(childs: 1)
  index(value: 1)
  index({adapter_id: 1, vcenter_id: 1})
end
