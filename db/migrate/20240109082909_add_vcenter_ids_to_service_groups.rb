class AddVcenterIdsToServiceGroups < ActiveRecord::Migration[5.2]
  def change
    add_column :service_groups, :vcenter_ids, :string, array: true, default: []
  end
end
