class AddServiceVpcIdToService < ActiveRecord::Migration[5.1]
  def change
    add_column :services, :service_vpc_id, :uuid
  end
end
