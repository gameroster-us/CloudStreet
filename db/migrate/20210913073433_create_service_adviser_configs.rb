# frozen_string_literal: false

# table for storing service adviser configuration
class CreateServiceAdviserConfigs < ActiveRecord::Migration[5.1]
  def change
    create_table :service_adviser_configs, id: :uuid do |t|
      t.uuid :account_id, null: false
      t.uuid :adapter_id
      t.string :provider_type, null: false
      t.string :config_type, null: false
      t.string :name, null: false
      t.string :category, null: false
      t.string :service_type
      t.jsonb :tags, default: {}
      t.jsonb :config_details, null: false
      t.timestamps
    end
  end
end
