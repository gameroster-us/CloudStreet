class ChangeSubnetFeildsName < ActiveRecord::Migration[5.1]
  def change

  	rename_column :subnets, :cidrblock, :cidr_block
  	rename_column :subnets, :availableip, :available_ip
  	rename_column :subnets, :availability, :availability_zone
 
  end
end
