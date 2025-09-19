class AddColumnToServiceGroup < ActiveRecord::Migration[5.1]
  def change
    add_column :service_groups, :sub_account_ids, :json, array: true, default: []
    add_column :service_groups, :project_ids, :json, array: true, default: []
  end
end
