class DropFilerTables < ActiveRecord::Migration[5.1]
  def change
    drop_table :filers
    drop_table :instance_filers
  end
end
