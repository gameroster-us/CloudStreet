class AddIpPermissionsEgressToSecurityGroups < ActiveRecord::Migration[5.1]
  def change
    add_column :security_groups, :ip_permissions_egress, :text
  end
end
