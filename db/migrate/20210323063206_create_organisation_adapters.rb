class CreateOrganisationAdapters < ActiveRecord::Migration[5.1]
  def change
    create_table :organisation_adapters, id: :uuid do |t|
      t.uuid :organisation_id
      t.uuid :adapter_id

      t.timestamps
    end

    add_foreign_key :organisation_adapters, :organisations
    add_foreign_key :organisation_adapters, :adapters
    add_index :organisation_adapters, [:organisation_id, :adapter_id]
		add_index :organisation_adapters, :adapter_id
  end
end
