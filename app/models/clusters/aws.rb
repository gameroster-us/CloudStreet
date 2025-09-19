class Clusters::AWS < Cluster  
  store_accessor :data, :allocated_storage, :backup_retention_period, :db_cluster_members, :db_cluster_parameter_group, :db_subnet_group, :endpoint, :engine, :engine_version, :port, :preferred_backup_window, :preferred_maintenance_window, :vpc_security_groups
end
