class AddDefaultRevisionValueToEnvironments < ActiveRecord::Migration[5.1]
  def change
    change_column :environments, :revision, :float, :default => 0.0
  end
end
