class AddDefaultValueToTags < ActiveRecord::Migration[5.1]
  def change
    change_column :tags, :is_mandatory, :boolean, :default => false
    change_column :environment_tags, :is_mandatory, :boolean, :default => false
  end
end
