class AddUserToCustomDashboard < ActiveRecord::Migration[5.1]
  def change
    add_reference :custom_dashboards, :user, type: :uuid, foreign_key: true
  end
end
