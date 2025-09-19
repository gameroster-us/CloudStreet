class AddAdditionalPropertiesToServices < ActiveRecord::Migration[5.1]
  def change
    add_column :services, :additional_properties, :json
  end
end
