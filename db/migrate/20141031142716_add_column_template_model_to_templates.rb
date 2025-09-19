class AddColumnTemplateModelToTemplates < ActiveRecord::Migration[5.1]
  def change
    add_column :templates, :template_model, :json
  end
end
