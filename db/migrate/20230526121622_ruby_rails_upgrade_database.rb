class RubyRailsUpgradeDatabase < ActiveRecord::Migration[5.2]
  def up
    sql = <<-SQL
      UPDATE gcp_resources set type = 'GCP::Resource::Compute::Disk' where type = 'Gcp::Resource::Compute::Disk';
      UPDATE gcp_resources set type = 'GCP::Resource::Compute::VirtualMachine' where type = 'Gcp::Resource::Compute::VirtualMachine';
      UPDATE gcp_resources set type = 'GCP::Resource::Compute::Snapshot' where type = 'Gcp::Resource::Compute::Snapshot';
      UPDATE gcp_resources set type = 'GCP::Resource::Container::GKS' where type = 'Gcp::Resource::Container::GKS';
      UPDATE gcp_resources set type = 'GCP::Resource::Compute::Image' where type = 'Gcp::Resource::Compute::Image';
      UPDATE aws_right_sizings set type = 'AWSRightSizing::S3' where type = 'AwsRightSizing::S3';
      UPDATE aws_right_sizings set type = 'AWSRightSizing::Rds' where type = 'AwsRightSizing::Rds';
    SQL

    ActiveRecord::Base.transaction do
      ActiveRecord::Base.connection.execute(sql)
    end
  end

  def down
    sql = <<-SQL
      UPDATE gcp_resources set type = 'Gcp::Resource::Compute::Disk' where type = 'GCP::Resource::Compute::Disk';
      UPDATE gcp_resources set type = 'Gcp::Resource::Compute::VirtualMachine' where type = 'GCP::Resource::Compute::VirtualMachine';
      UPDATE gcp_resources set type = 'Gcp::Resource::Compute::Snapshot' where type = 'GCP::Resource::Compute::Snapshot';
      UPDATE gcp_resources set type = 'Gcp::Resource::Container::GKS' where type = 'GCP::Resource::Container::GKS';
      UPDATE gcp_resources set type = 'Gcp::Resource::Compute::Image' where type = 'GCP::Resource::Compute::Image';
      UPDATE aws_right_sizings set type = 'AwsRightSizing::S3' where type = 'AWSRightSizing::S3';
      UPDATE aws_right_sizings set type = 'AwsRightSizing::Rds' where type = 'AWSRightSizing::Rds';
    SQL

    ActiveRecord::Base.transaction do
      ActiveRecord::Base.connection.execute(sql)
    end
  end
end
