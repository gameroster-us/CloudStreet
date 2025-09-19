class RemoveProjectIdsFromServiceGroup < ActiveRecord::Migration[5.1]
  def change
    remove_column :service_groups, :project_ids
  end
end
