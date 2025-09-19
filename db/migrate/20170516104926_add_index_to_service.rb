class AddIndexToService < ActiveRecord::Migration[5.1]
  def change
  	add_index :services, :type
  	add_index :services, :generic_type
  	add_index :interfaces, :service_id
  end
end
