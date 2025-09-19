class AddEnvironmentModelToEnvironments < ActiveRecord::Migration[5.1]
  def change
    add_column :environments, :environment_model, :json
  end
end
