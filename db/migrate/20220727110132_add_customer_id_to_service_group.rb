class AddCustomerIdToServiceGroup < ActiveRecord::Migration[5.1]
  def change
    add_column :service_groups, :customer_id, :string
    add_column :service_groups, :customer_name, :string
  end
end
