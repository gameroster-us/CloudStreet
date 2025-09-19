class AddColumnsToTemplates < ActiveRecord::Migration[5.1]
  def change
    add_column :templates, :region_id, :uuid
    add_column :templates, :adapter_id, :uuid
  end
end
