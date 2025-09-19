class AddCascadeDelete < ActiveRecord::Migration[5.1]
  def up
  	clear_orphans
  	add_foreign_key :templates, :adapters, on_delete: :cascade
  	add_foreign_key :aws_records, :adapters, on_delete: :cascade
  	add_foreign_key :adapters_machine_images, :adapters, on_delete: :cascade
  	add_foreign_key :vpcs, :adapters, on_delete: :cascade
  	add_foreign_key :subnets, :adapters, on_delete: :cascade
  	add_foreign_key :subnet_groups, :adapters, on_delete: :cascade
  	add_foreign_key :security_groups, :adapters, on_delete: :cascade
  	add_foreign_key :internet_gateways, :adapters, on_delete: :cascade
  	add_foreign_key :route_tables, :adapters, on_delete: :cascade
  	add_foreign_key :nacls, :adapters, on_delete: :cascade
  	add_foreign_key :resources, :adapters, on_delete: :cascade
  	add_foreign_key :snapshots, :adapters, on_delete: :cascade
  	add_foreign_key :encryption_keys, :adapters, on_delete: :cascade
    add_foreign_key :storages, :adapters, on_delete: :cascade
  	add_foreign_key :service_synchronization_histories, :adapters, on_delete: :cascade
  	remove_foreign_key :connections, :interfaces
    add_foreign_key :connections, :interfaces, on_delete: :cascade
    remove_foreign_key :connections, column: :remote_interface_id
    add_foreign_key :connections, :interfaces, column: :remote_interface_id, on_delete: :cascade
    remove_foreign_key :interfaces, :services
    add_foreign_key :interfaces, :services, on_delete: :cascade
    remove_foreign_key :services, :adapters
    add_foreign_key :services, :adapters, on_delete: :cascade
    remove_foreign_key :environments, column: :default_adapter_id
    add_foreign_key :environments, :adapters, column: :default_adapter_id, on_delete: :cascade
    remove_foreign_key :environment_services, :services
    add_foreign_key :environment_services, :services, on_delete: :cascade
    remove_foreign_key :environment_services, :environments
    add_foreign_key :environment_services, :environments, on_delete: :cascade

    remove_foreign_key :template_services, :templates
    add_foreign_key :template_services, :templates, on_delete: :cascade
    remove_foreign_key :template_services, :services
    add_foreign_key :template_services, :services, on_delete: :cascade
  end

  def down
  	remove_foreign_key :templates, :adapters
  	remove_foreign_key :aws_records, :adapters
  	remove_foreign_key :adapters_machine_images, :adapters
  	remove_foreign_key :vpcs, :adapters
  	remove_foreign_key :subnets, :adapters
  	remove_foreign_key :subnet_groups, :adapters
  	remove_foreign_key :security_groups, :adapters
  	remove_foreign_key :internet_gateways, :adapters
  	remove_foreign_key :route_tables, :adapters
  	remove_foreign_key :nacls, :adapters
  	remove_foreign_key :resources, :adapters
  	remove_foreign_key :snapshots, :adapters
  	remove_foreign_key :encryption_keys, :adapters
    remove_foreign_key :storages, :adapters
  	remove_foreign_key :service_synchronization_histories, :adapters
  	remove_foreign_key :connections, :interfaces
    add_foreign_key :connections, :interfaces
    remove_foreign_key :connections, column: :remote_interface_id
    add_foreign_key :connections, :interfaces, column: :remote_interface_id
    remove_foreign_key :interfaces, :services
    add_foreign_key :interfaces, :services
    remove_foreign_key :services, :adapters
    add_foreign_key :services, :adapters
    remove_foreign_key :environments, column: :default_adapter_id
    add_foreign_key :environments, :adapters, column: :default_adapter_id
    remove_foreign_key :environment_services, :services
    add_foreign_key :environment_services, :services
    remove_foreign_key :environment_services, :environments
    add_foreign_key :environment_services, :environments
    remove_foreign_key :template_services, :templates
    add_foreign_key :template_services, :templates
    remove_foreign_key :template_services, :services
    add_foreign_key :template_services, :services
  end


  def clear_orphans
  	begin
  	adapter_ids = Adapter.pluck(:id)
	  	Template.where.not(adapter_id: adapter_ids).delete_all
	  	AWSRecord.where.not(adapter_id: adapter_ids).delete_all
	  	AdaptersMachineImage.where.not(adapter_id: adapter_ids).delete_all
	  	
	  	Subnet.where.not(adapter_id: adapter_ids).delete_all
	  	SecurityGroup.where.not(adapter_id: adapter_ids).delete_all
	  	SubnetGroup.where.not(adapter_id: adapter_ids).delete_all
	  	InternetGateway.where.not(adapter_id: adapter_ids).delete_all
	  	RouteTable.where.not(adapter_id: adapter_ids).delete_all
	  	Nacl.where.not(adapter_id: adapter_ids).delete_all
	  	Resource.where.not(adapter_id: adapter_ids).delete_all
	  	Snapshot.where.not(adapter_id: adapter_ids).delete_all
	  	EncryptionKey.where.not(adapter_id: adapter_ids).delete_all
	  	ServiceSynchronizationHistory.where.not(adapter_id: adapter_ids).delete_all
	  	Vpc.where.not(adapter_id: adapter_ids).delete_all
    rescue Exception => e
    	CSLogger.error e.message
    	CSLogger.error e.backtrace
    end
  end
end
