# frozen_string_literal: true

# Model to access join table of Adapter and Task
class AdaptersTask < ApplicationRecord
  # Associations
  belongs_to :adapter
  belongs_to :task

  # Scopes
  scope :adapter_ids, ->(id) { where(adapter_id: id) }
  scope :without_adapter_ids, ->(id) { where.not(adapter_id: id) }
  scope :access, ->(tenant_access) { where(tenant_access: tenant_access) }
end
