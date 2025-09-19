class AddDataToStorage < ActiveRecord::Migration[5.1]
  def change
  	add_column :storages, :data, :json
  end
end
