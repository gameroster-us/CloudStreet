class AddDataFilerInstances < ActiveRecord::Migration[5.1]
  def change
  	add_column :instance_filers, :data, :json, default: {}
  end
end
