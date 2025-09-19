class ChangeDataTypeInServices < ActiveRecord::Migration[5.1]
  JSON_FIELDS_MAP = {
    'Services::Vpc' => ['internet_attached'],
    'Services::Network::SecurityGroup::AWS' => ['default', 'ip_permissions', 'ip_permissions_egress'],
    'Services::Network::RouteTable::AWS' => ['main', 'routes', 'associations'],
    'Services::Database::Rds::AWS' => ['iops', 'port', 'multi_az', 'allocated_storage', 'publicly_accessible', 'backup_retention_period', 'auto_minor_version_upgrade', 'preferred_backup_window_hour', 'preferred_backup_window_duration', 'preferred_maintenance_window_hour', 'preferred_maintenance_window_duration'],
    'Services::Compute::Server::AWS' => ['source_dest_check', 'source_dest_check'],
    'Services::Network::LoadBalancer::AWS' => ['connection_draining_timeout', 'cross_zone_load_balancing', 'unhealthy_threshold', 'connection_draining', 'ping_protocol_port', 'connection_timeout', 'healthy_threshold', 'response_timeout', 'hcheck_interval', 'listeners'],
    'Services::Compute::Server::Volume::AWS' => ['iops', 'size'],
    'Services::Network::AutoScalingConfiguration::AWS' => ['associate_public_ip', 'block_device_mappings'],
    'Services::Network::AutoScaling::AWS' => ['max_size', 'min_size', 'default_cooldown', 'desired_capacity', 'health_check_grace_period'],
    'Services::Network::Alarm::AWS' => ['period', 'threshold', 'alarm_actions', 'actions_enabled', 'evaluation_periods']
  }

  def change
    change_column :services, :data, 'json USING CAST(data AS json)'

    Service.reset_column_information
    CSLogger.info "--- Total #{Service.where(type: JSON_FIELDS_MAP.keys).count} services found"
    Service.where(type: JSON_FIELDS_MAP.keys).all.each do |s|
      next if s.data.blank?
      next unless s.data.kind_of? Hash
      s.data.slice(*JSON_FIELDS_MAP[s.type]).each do |key, val|
        s.data[key] = RubyStringJson.new(val).parse
      end
      s.data_will_change!
      s.save!
    end
  end
end
