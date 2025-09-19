class AddServiceGroupPolicyIdToServiceGroups < ActiveRecord::Migration[5.1]
  def change
    add_column :service_groups, :service_group_policy_id, :uuid, null: true
  end
end
