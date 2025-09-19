class ChangeProviderVpcIdInAzureRecord < ActiveRecord::Migration[5.1]
  def change
  	remove_column :azure_records, :vnet_id
  	add_column :azure_records, :vnet_ids, :uuid, array: true, default: []
  end
end
