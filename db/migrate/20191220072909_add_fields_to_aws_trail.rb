class AddFieldsToAWSTrail < ActiveRecord::Migration[5.1]
  def change
    add_column :aws_trails, :is_logs_encrypted_using_kms_key_id, :boolean
    add_column :aws_trails, :latest_log_delivery_error, :boolean
    add_column :aws_trails, :s3_bucket_object_lock, :boolean
    add_column :aws_trails, :s3_bucket_server_access_logging, :boolean
    add_column :aws_trails, :s3_bucket_mfa_delete_enabled, :boolean
    add_column :aws_trails, :s3_bucket_publicly_accessible, :boolean
    add_column :aws_trails, :mgmt_events_included, :boolean
  end
end
