class AddParentIdToOrganisations < ActiveRecord::Migration[5.1]
  def change
    add_column :organisations, :parent_id, :uuid
  end
end
