class AddTimeZoneToAccounts < ActiveRecord::Migration[5.1]
  def change
    add_column :accounts, :time_zone, :json
  end
end
