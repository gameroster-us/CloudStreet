class RemoveFieldsFromAWSTrail < ActiveRecord::Migration[5.1]
  def change
  	remove_column :aws_trails, :is_logs_encrypted_using_kms_key_id, :boolean
  	remove_column :aws_trails, :latest_log_delivery_error, :boolean
  	remove_column :aws_trails, :s3_bucket_object_lock, :boolean
  	remove_column :aws_trails, :s3_bucket_mfa_delete_enabled, :boolean
  	remove_column :aws_trails, :s3_bucket_publicly_accessible, :boolean
  	remove_column :aws_trails, :mgmt_events_included, :boolean
  	remove_column :aws_trails, :data_events_included, :boolean
    remove_column :aws_trails, :is_cloud_trail_config_enabled, :boolean
  	remove_column :aws_trails, :is_ct_integrated_with_cloud_watch, :boolean
  end
end