class AddRevisionToEnvironments < ActiveRecord::Migration[5.1]
  def change
    add_column :environments, :revision, :float
  end
end
