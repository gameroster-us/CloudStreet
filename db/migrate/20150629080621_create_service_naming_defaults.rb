class CreateServiceNamingDefaults < ActiveRecord::Migration[5.1]
  def change
    create_table :service_naming_defaults, id: :uuid do |t|
      t.string :prefix_service_name
      t.integer :suffix_service_count
      t.integer :last_used_number
      t.string :created_by
      t.string :updated_by
      t.uuid :account_id

      t.timestamps
    end
  end
end
