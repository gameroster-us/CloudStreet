class AddisActiveInOrganisations < ActiveRecord::Migration[5.1]
  def change
  	add_column :organisations, :is_active,:boolean, default: true
  end
end
