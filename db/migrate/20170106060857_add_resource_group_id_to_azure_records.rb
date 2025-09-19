class AddResourceGroupIdToAzureRecords < ActiveRecord::Migration[5.1]
  def change
    add_column :azure_records, :resource_group_id, :uuid
  end
end
