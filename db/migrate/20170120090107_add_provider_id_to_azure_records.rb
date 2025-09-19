class AddProviderIdToAzureRecords < ActiveRecord::Migration[5.1]
  def change
    add_column :azure_records, :provider_id, :text
  end
end
