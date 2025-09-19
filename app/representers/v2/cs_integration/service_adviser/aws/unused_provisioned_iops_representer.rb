module V2::CSIntegration::ServiceAdviser::AWS::UnusedProvisionedIopsRepresenter
	include Roar::JSON
	include Roar::Hypermedia


  property :id, getter:lambda{|args| self.id.to_s}
	property :name, getter:lambda{|args| self.provider_name}
	property :provider_id
	property :region_id
  property :current_storage_type, getter: lambda{ |args| self.current_storage_type ? MatricMaxUsageStorage::STORAGE_TYPE[self.current_storage_type] : "-" }
  property :recommanded_storage_type, getter: lambda{ |args| self.recommanded_storage_type ? MatricMaxUsageStorage::STORAGE_TYPE[self.recommanded_storage_type] : "-" }
  property :service_tag,getter: lambda{ |args| tag.collect{|key, value| {"tag_key"=> key, "tag_value"=> value} }}
  property :current_iops_usage
  property :recommanded_iops_usage
  property :monthly_estimated_cost
  property :created_at
  property :adapter_id
  property :aws_account_id
  property :configured_tag_key_value
  property :service_type
  property :comment_count
  def monthly_estimated_cost
    (actual_estimation_cost - recommanded_estimation_cost)*24*30
  end

  def configured_tag_key_value
    self.tag
  end

  def service_type
    self.provider_type
  end

end
