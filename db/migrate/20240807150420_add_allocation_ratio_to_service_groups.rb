class AddAllocationRatioToServiceGroups < ActiveRecord::Migration[5.2]
  def change
    add_column :service_groups, :allocation_ratio, :float, default: 1.0
  end
end
