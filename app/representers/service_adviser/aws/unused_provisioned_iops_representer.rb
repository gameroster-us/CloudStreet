module ServiceAdviser::AWS::UnusedProvisionedIopsRepresenter
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
  property :monthly_estimated_cost, getter: ->(args) { get_monthly_estimated_cost(args[:options][:user_options][:currency_rate]) }
  property :created_at
  property :adapter_id
  property :aws_account_id
  property :configured_tag_key_value
  property :service_type
  property :comment_count
  property :currency, getter: ->(args) { currency(args[:options][:user_options][:currency_code])}
  property :sa_recommendation_present, getter: ->(args) { sa_recommendation_present?(args[:options][:user_options][:current_tenant])}
  property :sa_recommendation_status, getter: ->(args) { sa_recommendation_status(args[:options][:user_options][:current_tenant])}



  # we require the adapter name property
  # inside service Adviser API response due 
  # to latest changes on adapter list api
  property :adapter_name, getter: lambda { |*| Adapters::AWS.find_by(id: adapter_id).try(:name) }

  def get_monthly_estimated_cost(currency_rate)
    (actual_estimation_cost - recommanded_estimation_cost)*24*30 * currency_rate
  end

  def configured_tag_key_value
    self.tag
  end

  def service_type
    self.provider_type
  end

  def currency(currency_code)
    currency_code.nil? ? 'USA' : currency_code
  end

  def sa_recommendation_present?(tenant)
    # We are getting unused provisioned iops based on aws account id, Hence not checking adapter_id present in tenant
    SaRecommendation.where(adapter_id: self.adapter_id, provider_id: self.provider_id, tenant_id: tenant.id).present?
  end

  def sa_recommendation_status(tenant)
    if sa_recommendation_present?(tenant)
      sa_recommendation = SaRecommendation.find_by(adapter_id: self.adapter_id, provider_id: self.provider_id, tenant_id: tenant.id)
      sa_recommendation.state rescue nil
    else
      'N/A'
    end
  end

end
