class AddGenericTypeToTemplates < ActiveRecord::Migration[5.1]
  def change
    add_column :templates, :generic_type, :boolean, default: false
  end
end
