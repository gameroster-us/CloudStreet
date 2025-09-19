class AddIsCtIntegratedWithCloudWatchToAWSTrails < ActiveRecord::Migration[5.1]
  def change
    add_column :aws_trails, :is_ct_integrated_with_cloud_watch, :boolean, default: true
  end
end
