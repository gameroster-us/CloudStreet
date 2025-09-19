class CreateReservationUtilizations < ActiveRecord::Migration[5.1]
  def change
    create_table :reservation_utilizations, id: :uuid do |t|
      t.references :adapter, type: :uuid, foreign_key: true
      t.string :grain
      t.string :reservation_order_id
      t.string :reservation_id
      t.datetime :date
      t.string :sku_name
      t.float :reserved_hours
      t.float :used_hours
      t.float :min_utilization_percentage
      t.float :avg_utilization_percentage
      t.float :max_utilization_percentage

      t.timestamps
    end
  end
end
