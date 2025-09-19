class AddReportProfileIdToOrganisations < ActiveRecord::Migration[5.1]
  def change
  	add_column :organisations, :report_profile_id, :string
  end
end
