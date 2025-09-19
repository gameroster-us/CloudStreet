class CreateAWSConfigs < ActiveRecord::Migration[5.1]
  def change
    create_table :aws_configs, id: :uuid do |t|
      t.uuid    :adapter_id
      t.uuid    :region_id
      t.string  :aws_account_id
      t.string  :name
      t.string  :role_arn
      t.string  :s3_bucket_name
      t.json    :configuration_recorders
      t.json    :configuration_recorder_status
      t.json    :delivery_channels

      t.timestamps
    end
  end
end
