class AddDataInVwEvent < ActiveRecord::Migration[5.1]
  def change
    add_column :vw_events, :data, :json, default: {}
  end
end
