class AddDescriptionToTemplates < ActiveRecord::Migration[5.1]
  def change
    add_column :templates, :description, :text, :default => ""
  end
end
