# frozen_string_literal: true

module SQLDBRecommendationRepresenter
  include Roar::JSON
  include Roar::Hypermedia

  property :adapter_id, getter: ->(args) { get_adapter_id(args[:options][:user_options][:current_tenant]) }
  property :sql_db_id, as: :id
  property :provider_id
  property :name
  property :region_id
  property :region_code
  property :subscription_id
  property :instancetype
  property :ahub_vm_tags
  property :costsavedpermonth
  property :ahub_monthly_estimated_cost
  property :monthly_estimated_cost
  property :service_type
  property :resource_group
  property :additional_properties
  property :currency, getter: ->(args) { args[:options][:user_options][:currency_details][:meta_data][:currency]}

  # we require the adapter name
  # inside service Adviser API response
  # due to latest changes on adapterlist api
  property :adapter_name
  property :sa_recommendation_present, getter: ->(args) { sa_recommendation_present?(args[:options][:user_options][:current_tenant])}
  property :sa_recommendation_status, getter: ->(args) { sa_recommendation_status(args[:options][:user_options][:current_tenant])}

  def region_code
    region = self[:region] || nil
    Region::AZURE_MAP[region]
  end

  def ahub_vm_tags
    tags =  self[:instancetags]
    separated_tags = tags.split('| ') rescue(nil)
    separated_tags = begin
                       separated_tags.map { |x| x = x.split(':'); { "tag_key": x.first, "tag_value": x.last } }
                     rescue StandardError
                       nil
                     end
  end

  def get_adapter_id(tenant)
    self.adapter_id_for_respresenter = tenant.adapters.azure_normal_active_adapters.where("data->'subscription_id'=?", self.subscription_id).first.try(:id)
  rescue StandardError
    nil
  end

  def service_type
    "AhubSqlDb"
  end

  def sql_db_id
    self.resource_for_respresenter = Azure::Resource.where(adapter_id: adapter_id_for_respresenter).where("provider_data->>'id'=?", self['provider_id']).first
    resource_for_respresenter.try(:id)
  rescue StandardError
    nil
  end

  def resource_group
    resource_for_respresenter.resource_group.name rescue nil
  end

  def additional_properties
    resource_for_respresenter.try(:additional_properties)
  end

  def monthly_estimated_cost
    try(:priceperunit).to_f * 24 * 30
  end

  def ahub_monthly_estimated_cost
    try(:ahub_priceperunit).to_f * 24 * 30
  end

  def adapter_name
    Adapters::Azure.find_by(id: adapter_id_for_respresenter).try(:name)
  end

  def sa_recommendation_present?(tenant)
    SaRecommendation.where(adapter_id: adapter_id_for_respresenter, provider_id: self.provider_id, tenant_id: tenant.id).present?
  end

  def sa_recommendation_status(tenant)
    if sa_recommendation_present?(tenant)
      sa_recommendation = SaRecommendation.find_by(adapter_id: adapter_id_for_respresenter, provider_id: self.provider_id, tenant_id: tenant.id)
      sa_recommendation.state rescue nil
    else
      'N/A'
    end
  end
end
