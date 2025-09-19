class AddReportProfileIdToTenant < ActiveRecord::Migration[5.1]
  def change
  	add_column :tenants, :report_profile_id, :string
  end
end
