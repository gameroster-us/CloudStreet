class CreateAdaptersAzureOffice365Services < ActiveRecord::Migration[5.2]
  def change
    create_table :adapters_azure_office365_services, id: :uuid do |t|
      t.references :adapter, type: :uuid, foreign_key: true, index: {:name => "index_adapters_azure_services_on_adapter_id"}
      t.references :azure_office365_service, type: :uuid, foreign_key: true, index: {:name => "index_adapters_azure_services_on_service_id"}
      t.boolean :is_deleted, default: false

      t.timestamps
    end
  end
end
