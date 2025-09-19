class AddS3BucketMissingToAWSConfig < ActiveRecord::Migration[5.1]
  def change
  	add_column :aws_configs, :is_s3_bucket_missing , :boolean
  end
end
