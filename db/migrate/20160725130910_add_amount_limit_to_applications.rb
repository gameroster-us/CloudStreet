class AddAmountLimitToApplications < ActiveRecord::Migration[5.1]
  def change
    add_column :applications, :max_amount, :integer
    add_column :applications, :notify, :boolean
    add_column :applications, :access_roles, :uuid, array: true, default: []
    add_column :applications, :notify_to, :uuid, array: true, default: []
  end
end
