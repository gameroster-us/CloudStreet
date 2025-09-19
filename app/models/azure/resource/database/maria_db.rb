class Azure::Resource::Database::MariaDB < Azure::Resource::Database
  self.abstract_class = true
  store_accessor :data, :sku, :version, :ssl_enforcement, :domain_name, :backup_retention_days, :storage_size_in_mb, :db_status
end
