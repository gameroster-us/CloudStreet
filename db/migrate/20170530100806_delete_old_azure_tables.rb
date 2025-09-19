class DeleteOldAzureTables < ActiveRecord::Migration[5.1]
  def change
    drop_table :azure_records if (table_exists? :azure_records)
    drop_table :azure_services if (table_exists? :azure_services)
  end
end
