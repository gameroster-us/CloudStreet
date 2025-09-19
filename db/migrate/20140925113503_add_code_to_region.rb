class AddCodeToRegion < ActiveRecord::Migration[5.1]
  def change
    add_column :regions, :code, :string
  end
end
