class AddIsCloudTrailConfigEnabledToAWSTrails < ActiveRecord::Migration[5.1]
  def change
    add_column :aws_trails, :is_cloud_trail_config_enabled, :boolean, default: true
  end
end
