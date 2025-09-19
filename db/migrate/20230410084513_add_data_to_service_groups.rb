class AddDataToServiceGroups < ActiveRecord::Migration[5.1]
  def change
    add_column :service_groups, :data, :jsonb, default: {}
  end
end
