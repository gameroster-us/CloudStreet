# S3 rightsizing API represnter
module S3RightsizingRepresenter
  include Roar::JSON
  include Roar::Hypermedia

  property :key
  property :aws_account_id
  property :region_id
  property :region
  property :storage_class
  property :new_storage_class
  property :price
  property :resize_price
  property :cost_save_per_month
  property :adapter_name
  property :adapter_id
  property :size
  property :chart_data
  property :comment_count
  property :service_type
  property :currency, getter: ->(args) { args[:options][:user_options][:currency_details][:meta_data][:currency]}
  property :sa_recommendation_present, getter: ->(args) { sa_recommendation_present?(args[:options][:user_options][:current_tenant])}
  property :sa_recommendation_status, getter: ->(args) { sa_recommendation_status(args[:options][:user_options][:current_tenant])}

  def region
    region = begin
              self[:region]
            rescue
              nil
            end
    Region.find_by(code: region)&.region_name
  end

  def region_id
    region = begin
               self[:region]
             rescue
               nil
             end
    Region.find_by(code: region)&.id
  end

  def chart_data
    [{
        label: "Put Copy Post List Request",
        value: put_copy_post_list_request
      },
      {
        label: "Get Select and Other Request",
        value: get_select_other_request
      },
      {
        label: "Lifecycle Transition Request",
        value: lifecycle_transition_request
      },
      {
        label: "Data Retrival Request",
        value: data_retrival_request
      }
    ]
  end

  def service_type
    'rightsized_s3'
  end

  def sa_recommendation_present?(tenant)
    SaRecommendation.where(adapter_id: self.adapter_id, tenant_id: tenant.id, provider_id: self.key).present?
  end

  def sa_recommendation_status(tenant)
    if sa_recommendation_present?(tenant)
      sa_recommendation = SaRecommendation.find_by(adapter_id: self.adapter_id, provider_id: self.key, tenant_id: tenant.id)
      sa_recommendation.state rescue nil
    else
      'N/A'
    end
  end
end
