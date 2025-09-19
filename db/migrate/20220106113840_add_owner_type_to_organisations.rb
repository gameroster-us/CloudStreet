class AddOwnerTypeToOrganisations < ActiveRecord::Migration[5.1]
  def change
    add_column :organisations, :owner_type, :integer, default: 0
  end
end
