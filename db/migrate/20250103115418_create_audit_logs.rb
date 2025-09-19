class CreateAuditLogs < ActiveRecord::Migration[5.2]
  def change
    create_table :audit_logs, id: :uuid do |t|
      t.string :auditable_type, null: false
      t.uuid :auditable_id, null: false
      t.string :event, null: false
      t.jsonb :object, default: {}
      t.jsonb :object_changes, default: {}
      t.string :modifier_name
      t.uuid :organisation_id
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end

    add_index :audit_logs, [:auditable_type, :auditable_id]
    add_index :audit_logs, :organisation_id
  end
end
