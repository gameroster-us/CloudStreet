class CreateTenants < ActiveRecord::Migration[5.1]
  def change
    create_table :tenants, id: :uuid do |t|
      t.text :name
      t.string :state
      t.uuid :organisation_id

      t.timestamps
    end
    add_foreign_key :tenants, :organisations, on_delete: :cascade
    add_index :tenants, :organisation_id
  end
end
