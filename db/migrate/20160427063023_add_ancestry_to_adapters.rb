class AddAncestryToAdapters < ActiveRecord::Migration[5.1]
  def change
    add_column :adapters, :ancestry, :string
    add_index :adapters, :ancestry
  end
end
