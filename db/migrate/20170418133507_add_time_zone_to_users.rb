class AddTimeZoneToUsers < ActiveRecord::Migration[5.1]
  def up
  	add_column :users, :time_zone, :json
  end
end
