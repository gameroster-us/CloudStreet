# frozen_string_literal: true

# Migration to add default_tenant_visibility column with default value as true
class AddDefaultTenantVisibilityToGeneralSetting < ActiveRecord::Migration[5.1]
  def change
    add_column :general_settings, :default_tenant_visibility, :boolean, default: true
  end
end
