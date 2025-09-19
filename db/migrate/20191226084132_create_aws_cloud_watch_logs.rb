class CreateAWSCloudWatchLogs < ActiveRecord::Migration[5.1]
  def change
    create_table :aws_cloud_watch_logs, id: :uuid do |t|
      t.uuid    :adapter_id, index: true
      t.uuid    :region_id, index: true
      t.uuid    :account_id, index: true

      t.string  :aws_account_id
      t.string  :region_code
      t.json    :alarm_configured
      t.json    :console_sign_in_without_mfa
      t.json    :monitored_aws_organizations_changes
      t.json    :authorization_failures_alarm_monitored
      t.json    :cmk_configuration_changes_monitored
      t.json    :alarm_configured_for_cloud_trail
      t.json    :monitored_sign_in_failures
      t.json    :monitored_ec2_instance_changes
      t.json    :monitored_large_ec2_instances_changes
      t.json    :monitored_iam_policy_changes
      t.json    :monitored_igw_changes
      t.json    :monitored_nacl_changes
      t.json    :monitored_root_account
      t.json    :monitored_route_table_changes
      t.json    :monitored_s3_bucket_changes
      t.json    :monitored_security_group_changes
      t.json    :monitored_vpc_changes

      t.timestamps
    end
  end
end
