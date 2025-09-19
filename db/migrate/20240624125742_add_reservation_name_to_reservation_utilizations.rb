class AddReservationNameToReservationUtilizations < ActiveRecord::Migration[5.2]
  def change
    add_column :reservation_utilizations, :reservation_name, :string
  end
end
