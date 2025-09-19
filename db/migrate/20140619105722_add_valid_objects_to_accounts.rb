class AddValidObjectsToAccounts < ActiveRecord::Migration[5.1]
  def change
    add_column :accounts, :accountable_objects, :integer, :default => 30
  end
end
