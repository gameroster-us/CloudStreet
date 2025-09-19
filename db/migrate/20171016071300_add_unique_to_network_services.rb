class AddUniqueToNetworkServices < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def up
  	clean_duplicates
  	add_index :vpcs, [:adapter_id, :region_id, :vpc_id], :unique => true, algorithm: :concurrently unless index_exists?(:vpcs, [:adapter_id, :region_id, :vpc_id])
  	add_index :internet_gateways, [:adapter_id, :region_id, :vpc_id, :provider_id], :unique => true, algorithm: :concurrently, name: "index_ig_on_adapter_id_and_region_id_and_vpc_id_and_provider_id" unless index_exists?(:internet_gateways, [:adapter_id, :region_id, :vpc_id, :provider_id], name: "index_ig_on_adapter_id_and_region_id_and_vpc_id_and_provider_id")
  	add_index :subnets, [:adapter_id, :region_id, :vpc_id, :provider_id], :unique => true, algorithm: :concurrently, name: "index_sb_on_adapter_id_and_region_id_and_vpc_id_and_provider_id" unless index_exists?(:subnets, [:adapter_id, :region_id, :vpc_id, :provider_id], name: "index_sb_on_adapter_id_and_region_id_and_vpc_id_and_provider_id")
  	add_index :security_groups, [:adapter_id, :region_id, :vpc_id, :group_id], :unique => true, algorithm: :concurrently, name: "index_sg_on_adapter_id_and_region_id_and_vpc_id_and_provider_id" unless index_exists?(:security_groups, [:adapter_id, :region_id, :vpc_id, :group_id], name: "index_sg_on_adapter_id_and_region_id_and_vpc_id_and_provider_id")
  	add_index :subnet_groups, [:adapter_id, :region_id, :provider_id], :unique => true, algorithm: :concurrently unless index_exists?(:subnet_groups, [:adapter_id, :region_id, :provider_id])
  	add_index :route_tables, [:adapter_id, :region_id, :vpc_id, :provider_id], :unique => true, algorithm: :concurrently, name: "index_rt_on_adapter_id_and_region_id_and_vpc_id_and_provider_id" unless index_exists?(:route_tables, [:adapter_id, :region_id, :vpc_id, :provider_id], name: "index_rt_on_adapter_id_and_region_id_and_vpc_id_and_provider_id")
  	add_index :nacls, [:adapter_id, :region_id, :vpc_id, :provider_id], :unique => true, algorithm: :concurrently, name: "index_nacls_on_adapter_and_region_and_vpc_and_provider" unless index_exists?(:nacls, [:adapter_id, :region_id, :vpc_id, :provider_id], name: "index_nacls_on_adapter_and_region_and_vpc_and_provider")
  end

  def down
  	remove_index :vpcs, [:adapter_id, :region_id, :vpc_id] if index_exists?(:vpcs, [:adapter_id, :region_id, :vpc_id])
  	remove_index :internet_gateways, name: "index_ig_on_adapter_id_and_region_id_and_vpc_id_and_provider_id" if index_exists?(:internet_gateways, [:adapter_id, :region_id, :vpc_id, :provider_id], name: "index_ig_on_adapter_id_and_region_id_and_vpc_id_and_provider_id")
  	remove_index :subnets, name: "index_sb_on_adapter_id_and_region_id_and_vpc_id_and_provider_id" if index_exists?(:subnets, [:adapter_id, :region_id, :vpc_id, :provider_id], name: "index_sb_on_adapter_id_and_region_id_and_vpc_id_and_provider_id")
  	remove_index :security_groups, name: "index_sg_on_adapter_id_and_region_id_and_vpc_id_and_provider_id" if index_exists?(:security_groups, [:adapter_id, :region_id, :vpc_id, :group_id], name: "index_sg_on_adapter_id_and_region_id_and_vpc_id_and_provider_id")
    remove_index :subnet_groups, [:adapter_id, :region_id, :provider_id] if index_exists?(:subnet_groups, [:adapter_id, :region_id, :provider_id])
    remove_index :route_tables, name: "index_rt_on_adapter_id_and_region_id_and_vpc_id_and_provider_id" if index_exists?(:route_tables, [:adapter_id, :region_id, :vpc_id, :provider_id], name: "index_rt_on_adapter_id_and_region_id_and_vpc_id_and_provider_id")
    remove_index :nacls, name: "index_nacls_on_adapter_and_region_and_vpc_and_provider" if index_exists?(:nacls, [:adapter_id, :region_id, :vpc_id, :provider_id], name: "index_nacls_on_adapter_and_region_and_vpc_and_provider")
  end

  def clean_duplicates
  	vpcs_count = Vpc.group(:vpc_id,:adapter_id,:region_id).count
  	vpcs_count.each do |key, count|
  		if count > 1 && key[0].present?
  			latest_id = Vpc.where(vpc_id: key[0], adapter_id: key[1], region_id: key[2]).order('created_at DESC').first.id
  			Vpc.where(vpc_id: key[0], adapter_id: key[1], region_id: key[2]).where.not(id: latest_id).where.not(id: latest_id).destroy_all
  		end
  	end

  	internet_gateways_count = InternetGateway.group(:provider_id, :vpc_id,:adapter_id,:region_id).count

  	internet_gateways_count.each do |key,count|
  	  if count > 1 && key[0].present?
  		latest_id = InternetGateway.where(provider_id: key[0],vpc_id: key[1], adapter_id: key[2], region_id: key[3]).order('created_at DESC').first.id
  		InternetGateway.where(provider_id: key[0],vpc_id: key[1], adapter_id: key[2], region_id: key[3]).where.not(id: latest_id).destroy_all
  	  end
  	end

  	subnets_count = Subnet.group(:provider_id, :vpc_id,:adapter_id,:region_id).count

  	subnets_count.each do |key,count|
  	  if count > 1 && key[0].present?
  		latest_id = Subnet.where(provider_id: key[0],vpc_id: key[1], adapter_id: key[2], region_id: key[3]).first.id
  		Subnet.where(provider_id: key[0],vpc_id: key[1], adapter_id: key[2], region_id: key[3]).where.not(id: latest_id).destroy_all
  	  end
  	end

  	security_groups_count = SecurityGroup.group(:group_id, :vpc_id,:adapter_id,:region_id).count

  	security_groups_count.each do |key,count|
	  if count > 1 && key[0].present?
		latest_id = SecurityGroup.where(group_id: key[0],vpc_id: key[1], adapter_id: key[2], region_id: key[3]).order('created_at DESC').first.id
		SecurityGroup.where(group_id: key[0],vpc_id: key[1], adapter_id: key[2], region_id: key[3]).where.not(id: latest_id).destroy_all
	  end
  	end

  	subnet_groups_count = SubnetGroup.unscoped.group(:name,:adapter_id,:region_id).count

  	subnet_groups_count.each do |key,count|
	  if count > 1 && key[0].present?
		latest_id = SubnetGroup.unscoped.where(name: key[0], adapter_id: key[1], region_id: key[2]).order('created_at DESC').first.id
		SubnetGroup.unscoped.where(name: key[0], adapter_id: key[1], region_id: key[2]).where.not(id: latest_id).destroy_all
	  end
  	end


  	route_tables_count = RouteTable.group(:provider_id, :vpc_id,:adapter_id,:region_id).count

  	route_tables_count.each do |key,count|
  	  if count > 1 && key[0].present?
  		latest_id = RouteTable.where(provider_id: key[0],vpc_id: key[1], adapter_id: key[2], region_id: key[3]).order('created_at DESC').first.id
  		RouteTable.where(provider_id: key[0],vpc_id: key[1], adapter_id: key[2], region_id: key[3]).where.not(id: latest_id).destroy_all
  	  end
  	end

  	nacls_count = Nacl.group(:provider_id, :vpc_id,:adapter_id,:region_id).count

  	nacls_count.each do |key,count|
  	  if count > 1 && key[0].present?
  		latest_id = Nacl.where(provider_id: key[0],vpc_id: key[1], adapter_id: key[2], region_id: key[3]).first.id
  		Nacl.where(provider_id: key[0],vpc_id: key[1], adapter_id: key[2], region_id: key[3]).where.not(id: latest_id).destroy_all
  	  end
  	end

  end
end
