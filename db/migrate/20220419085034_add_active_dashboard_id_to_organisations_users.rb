class AddActiveDashboardIdToOrganisationsUsers < ActiveRecord::Migration[5.1]
  def change
    unless ActiveRecord::Base.connection.column_exists?(:organisations_users, :active_dashboard_id)
      add_column :organisations_users, :active_dashboard_id, :string
    end
  end
end
