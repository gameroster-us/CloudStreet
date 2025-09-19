class AddTypeFieldToTags < ActiveRecord::Migration[5.1]
  def change
    [:tags, :environment_tags].each do |param|
      add_column param, :applied_type, :string, default: 'Provider'
    end
    add_column :environment_tags, :selected_type, :integer, default: 2
  end
end
