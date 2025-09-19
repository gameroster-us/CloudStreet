class CSProdV134 < ActiveRecord::Migration[5.1]
  def up
    #Cleanup security scan storage for removing old data set
    SecurityScanStorage.delete_all
    UserRole.where.not(name: ['Administrator', 'CloudStreetMarketplaceAMIAdmin', 'Viewer']).each do |role|
      access_right = AccessRight.find_by_code('cs_financial_dashboard_view')
      AccessRightsUserRoles.find_or_create_by({ user_role_id: role.id, access_right_id: access_right.id })
    end
  end
end
