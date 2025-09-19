class AddNameToAdapters < ActiveRecord::Migration[5.1]
  def change
    add_column :adapters, :name, :text
  end
end
