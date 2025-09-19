class AddOverrideServiceTagsToEnvironmentTags < ActiveRecord::Migration[5.1]
  def change
    add_column :environment_tags, :override_service_tags, :boolean, default: false
  end
end
