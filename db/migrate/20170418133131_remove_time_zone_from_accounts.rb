class RemoveTimeZoneFromAccounts < ActiveRecord::Migration[5.1]
  def change
  	remove_column :accounts, :time_zone
  end
end
