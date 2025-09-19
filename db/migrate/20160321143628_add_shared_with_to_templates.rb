class AddSharedWithToTemplates < ActiveRecord::Migration[5.1]
  def change
  	add_column :templates, :shared_with, :uuid, array: true, default: [], :null => false
  end
end
