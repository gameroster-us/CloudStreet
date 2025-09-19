class CreateServiceGroups < ActiveRecord::Migration[5.1]
  def change
    create_table :service_groups, id: :uuid do |t|
      t.uuid   :account_id
      t.uuid   :tenant_id
      t.string :type
      t.string :name
      t.string :description
      t.string :provider_type
      t.string :adapter_group_ids, array: true, default: []
      t.string :tag_group_ids, array: true, default: []
      t.json :adapter_ids, array: true, default: []
      t.json :tags, array: true, default: []

      t.timestamps
    end
  end
end
