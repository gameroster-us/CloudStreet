class ChangeEventsDataToJson < ActiveRecord::Migration[5.1]
  def change
    change_column :events, :data, "json USING CAST(data AS json)" #:json
  end
end
