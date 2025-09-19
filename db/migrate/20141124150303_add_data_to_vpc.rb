class AddDataToVpc < ActiveRecord::Migration[5.1]
  def change
    add_column :vpcs, :data, :json
  end
end
