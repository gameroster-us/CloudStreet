class AddCreatedByToTemplates < ActiveRecord::Migration[5.1]
  def change
    add_column :templates, :created_by, :uuid
    add_column :templates, :updated_by, :uuid
  end
end
