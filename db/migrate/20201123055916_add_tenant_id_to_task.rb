# frozen_string_literal: true

# Adding tenant_id column to Task model
class AddTenantIdToTask < ActiveRecord::Migration[5.1]
  def change
    add_column :tasks, :tenant_id, :uuid
    add_index :tasks, :tenant_id
  end
end
