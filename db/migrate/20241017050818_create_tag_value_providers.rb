class CreateTagValueProviders < ActiveRecord::Migration[5.2]
  def change
    create_table :tag_value_providers, id: :uuid do |t|
      t.string :provider_type
      t.string :account_id
      t.string :subscription_id
      t.string :sub_account_id
      t.string :vcenter_id
      t.string :gcp_project_id
      t.references :adapter, type: :uuid, foreign_key: true
      t.json :tags_cols, array: true, default: []
      t.json :label_keys, array: true, default: []
      t.jsonb :tags_data, array: true, default: []
      t.timestamps
    end
  end
end
