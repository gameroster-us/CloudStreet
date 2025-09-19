# frozen_string_literal: false

# Model for storing Group data version
class RecordVersion < ApplicationRecord
  belongs_to :versionable, polymorphic: true
  belongs_to :service_group

  validates :data_changes, presence: true
end
