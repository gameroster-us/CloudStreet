class CreateAzureOffice365Services < ActiveRecord::Migration[5.2]
  def change
    create_table :azure_office365_services, id: :uuid do |t|
      t.string :service_name

      t.timestamps
    end
  end
end
