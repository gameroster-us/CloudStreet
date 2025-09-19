class RemoveForeignKeyVwInventories < ActiveRecord::Migration[5.1]
  def change
  	remove_foreign_key :vw_events, :vw_inventories
  end
end
