class AddTemplateTagsToTemplate < ActiveRecord::Migration[5.1]
  def change
    add_column :templates, :template_tags, :json, default: {}
    add_column :templates, :selected_type, :integer, default: 2
  end
end
