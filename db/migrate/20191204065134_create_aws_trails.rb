class CreateAWSTrails < ActiveRecord::Migration[5.1]
  def change
    create_table :aws_trails, id: :uuid do |t|
      t.uuid    :adapter_id, index: true
      t.uuid    :region_id, index: true

      t.string  :name
      t.string  :cloud_watch_logs_log_group_arn
      t.string  :cloud_watch_logs_role_arn
      t.string  :home_region
      t.boolean :has_custom_event_selectors
      t.boolean :include_global_service_events
      t.boolean :is_multi_region_trail 
      t.boolean :is_organization_trail
      t.string  :kms_key_id
      t.boolean :log_file_validation_enabled
      t.string  :s3_key_prefix
      t.string  :s3_bucket_name
      t.string  :sns_topic_name
      t.string  :sns_topic_arn
      t.string  :trail_arn
       
      t.timestamps
    end
  end
end
