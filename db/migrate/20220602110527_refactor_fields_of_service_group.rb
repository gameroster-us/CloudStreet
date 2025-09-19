class RefactorFieldsOfServiceGroup < ActiveRecord::Migration[5.1]
  def up
    add_column :service_groups, :normal_adapter_ids, :string, array: true, default: []
    add_column :service_groups, :custom_data, :jsonb, default: {}

    change_column :service_groups, :type, :string, null: true

    remove_column :service_groups, :adapter_group_ids
    remove_column :service_groups, :tag_group_ids
  end

  def down
    change_column :service_groups, :type, :string, null: false
    remove_column :service_groups, :normal_adapter_ids
    remove_column :service_groups, :custom_data

    add_column :service_groups, :adapter_group_ids, :json, array: true, default: []
    add_column :service_groups, :tag_group_ids, :json, array: true, default: []
  end
end
