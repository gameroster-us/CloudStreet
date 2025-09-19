class AddFieldsToTags < ActiveRecord::Migration[5.1]
  def change
    [:tags, :environment_tags].each do |table|
      add_column table , :applicable_services, :string,  array: true, default: []
      add_column table , :overridable_services, :string,  array: true, default: []
      add_column table , :description, :text
    end
  end
end
