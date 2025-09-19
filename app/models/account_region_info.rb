class AccountRegionInfo

  attr_accessor :region_id, :region_name, :adapter_type, :enabled, :billing_stats, :code, :adapter_id

  def initialize(account_region, tenant, account=nil)
    region        = account_region.region
    @enabled      = account_region.enabled
    @region_id    = region.id
    @region_name  = region.region_name
    @code  = region.code
    @current_tenant = tenant
    @billing_stats = account_region.billing_stats
  end

end
