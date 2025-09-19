class AuditLog < ApplicationRecord
  belongs_to :auditable, polymorphic: true

  validates :auditable_type, :auditable_id, :event, presence: true
end