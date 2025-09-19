class AddFieldsToAWSTrails < ActiveRecord::Migration[5.1]
  def change
  	add_column :aws_trails, :provider_name, :string 
  	add_column :aws_trails, :aws_account_id,:string 
  	add_column :aws_trails, :data_resources, :json
  	add_column :aws_trails, :latest_delivery_error, :string
  	add_column :aws_trails, :include_management_events ,:boolean
  	add_column :aws_trails, :s3_lock_configuration, :json
  end
end
