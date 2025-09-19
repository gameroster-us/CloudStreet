# frozen_string_literal: true

module VirtualMachinesRightsizingRepresenter
  include Roar::JSON
  include Roar::Hypermedia

  property :adapter_id, getter: ->(args) { get_adapter_id(args[:options][:user_options][:current_tenant]) }
  property :vm_id, as: :id
  property :provider_id
  property :name
  property :region_id
  property :region_code
  property :subscription_id
  property :vcpu
  property :memory
  property :storage
  property :instancetype
  property :resizetype
  property :vm_tags
  property :networkperformance
  property :costsavedpermonth
  property :service_type
  property :resource_group
  property :state
  property :comment_count
  property :additional_properties
  property :currency, getter: ->(args) { args[:options][:user_options][:currency_details][:meta_data][:currency]}
  property :sa_recommendation_present, getter: ->(args) { sa_recommendation_present?(args[:options][:user_options][:current_tenant])}
  property :sa_recommendation_status, getter: ->(args) { sa_recommendation_status(args[:options][:user_options][:current_tenant])}
  property :azure_subscription_name
  property :maxcpu
  property :maxmem

  # we require the adapter name
  # inside service Adviser API response
  # due to latest changes on adapterlist api
  property :adapter_name
  # we added Azure VmrightSizing Unoptimized metric_days based on service_adviser_config
  property :metric_duration_days

  def region_code
    region = self[:region] || nil
    Region::AZURE_MAP[region]
  end

  def vm_tags
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
    "VirtualMachine"
  end

  def vm_id
    self.resource_for_respresenter = Azure::Resource.where(adapter_id: adapter_id_for_respresenter).where("provider_data->>'id'=?", self['provider_id']).first
    resource_for_respresenter.try(:id)
  rescue StandardError
    nil
  end

  def resource_group
    resource_for_respresenter.resource_group.name rescue nil
  end

  def state
    resource_for_respresenter.try(:vm_status) rescue nil
  end
  
  def additional_properties
    # Fetch the pricetype property from resource table directly
    price_type_prop = resource_for_respresenter.try(:additional_properties) || {}
    self[:additional_properties].try(:merge, price_type_prop) || {}
  end

  def sa_recommendation_present?(tenant)
    SaRecommendation.where(adapter_id: adapter_id_for_respresenter, tenant_id: tenant.id, provider_id: self.provider_id).present?
  end

  def adapter_name
    Adapters::Azure.find_by(id: adapter_id_for_respresenter).try(:name)
  end

  def sa_recommendation_status(tenant)
    if sa_recommendation_present?(tenant)
      sa_recommendation = SaRecommendation.find_by(adapter_id: adapter_id_for_respresenter, provider_id: self.provider_id, tenant_id: tenant.id)
      sa_recommendation.state rescue nil
    else
      'N/A'
    end
  end

  def azure_subscription_name
    Adapters::Azure.where(id: adapter_id_for_respresenter).first&.subscription.try(:display_name)
  end

  def maxcpu
    self[:maxcpu]
  rescue
    nil
  end

  def maxmem
    self[:maxmem]
  rescue
    nil
  end

  def metric_duration_days
    service_adviser_config = ServiceAdviserConfig.where(account_id: account_id).azure_unoptimized_vm_default_config
    metrics_duration = service_adviser_config.config_details["metric_duration_hours"].to_i
    (metrics_duration / 24).to_i
  end

end
