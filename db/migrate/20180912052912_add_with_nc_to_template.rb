class AddWithNcToTemplate < ActiveRecord::Migration[5.1]
  def change
    add_column :templates, :with_nc, :boolean, :default => false
  end
end
