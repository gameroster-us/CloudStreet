class AddDataToEnvironmentTag < ActiveRecord::Migration[5.1]
  def change
    add_column :environment_tags, :data, :json
    add_column :environment_tags, :apply_naming_param, :boolean, default: false
  end
end
