class AddIgnoredFromToStorage < ActiveRecord::Migration[5.1]
  def change
    add_column :storages, :ignored_from, :string, array: true, default: ['un-ignored'], null: false
  end
end
