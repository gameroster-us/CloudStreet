class AddTimeZoneToGeneralSettings < ActiveRecord::Migration[5.1]
  def change
    add_column :general_settings, :time_zone, :json, default: {region: "Australia", org_time_zone: "Brisbane"}
  end
end
