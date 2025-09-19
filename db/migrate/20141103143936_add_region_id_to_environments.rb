class AddRegionIdToEnvironments < ActiveRecord::Migration[5.1]
  def change
    add_column :environments, :region_id, :uuid
  end
end
