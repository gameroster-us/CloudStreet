class AddCreatedByToEnvironments < ActiveRecord::Migration[5.1]
  def change
    add_column :environments, :created_by, :uuid
    add_column :environments, :updated_by, :uuid
  end
end
