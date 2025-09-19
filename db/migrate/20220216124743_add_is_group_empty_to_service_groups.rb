class AddIsGroupEmptyToServiceGroups < ActiveRecord::Migration[5.1]
  def change
    add_column :service_groups, :is_group_empty, :boolean, default: false
  end
end
