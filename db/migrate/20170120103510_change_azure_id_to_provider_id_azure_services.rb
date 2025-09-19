class ChangeAzureIdToProviderIdAzureServices < ActiveRecord::Migration[5.1]
  def change
    if column_exists? :azure_services, :azure_id
      rename_column :azure_services, :azure_id, :provider_id
    end
  end
end
