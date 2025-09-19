# frozen_string_literal: true

# Migration to add tenant_access column with default value as true
class AddTenantAccessToAdaptersTask < ActiveRecord::Migration[5.1]
  def change
    add_column :adapters_tasks, :tenant_access, :boolean, default: true
    add_index :adapters_tasks, :tenant_access
  end
end
