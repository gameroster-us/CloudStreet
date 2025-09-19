class AddCostToApplications < ActiveRecord::Migration[5.1]
  def change
    add_column :applications, :cost, :float,:default=> 00
  end
end
