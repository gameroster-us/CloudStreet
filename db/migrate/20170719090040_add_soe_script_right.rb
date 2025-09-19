class AddSoeScriptRight < ActiveRecord::Migration[5.1]
  def self.up
    access_right = AccessRight.find_or_create_by(code: "cs_ami_soe_scripts", title: "Manage SOE Scripts")
    UserRole.where(name: ['Administrator', 'CloudStreetMarketplaceAMIAdmin']).each do|role|
      AccessRightsUserRoles.find_or_create_by({ user_role_id: role.id, access_right_id: access_right.id })
    end
  end

  def self.down
  end
end
