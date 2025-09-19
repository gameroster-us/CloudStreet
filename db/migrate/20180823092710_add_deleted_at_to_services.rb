class AddDeletedAtToServices < ActiveRecord::Migration[5.1]
  def change
    add_column :services, :deleted_at, :datetime
    add_index :services, :deleted_at
    add_index :services, [:id, :provider_id, :deleted_at], unique: true
  end
end
