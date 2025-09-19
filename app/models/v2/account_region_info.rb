# frozen_string_literal: true

# this class used as model to initialize account region only for xui(CMP)
class V2::AccountRegionInfo

  attr_accessor :region_id, :region_name, :adapter_type, :enabled, :code, :adapter_id

  def initialize(account_region, tenant)
    region = account_region.region
    @enabled = account_region.enabled
    @region_id = region.id
    @region_name = region.region_name
    @current_tenant = tenant
    @adapter_type = region.adapter.try(:type)
    @code = region.code
    @adapter_id = account_region.region.adapter_id
  end

end
