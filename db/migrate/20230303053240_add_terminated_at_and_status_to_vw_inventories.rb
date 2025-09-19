class AddTerminatedAtAndStatusToVwInventories < ActiveRecord::Migration[5.1]
  def change
    add_column :vw_inventories, :status, :string
    add_column :vw_inventories, :terminated_at, :datetime
  end
end
