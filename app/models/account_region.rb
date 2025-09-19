class AccountRegion < ApplicationRecord
  belongs_to :account
  belongs_to :region
  scope :by_provider_id,  ->(provider_id) { joins(:region).where('adapter_id = ?',provider_id).order('region_name asc') }
  scope :include_regions, ->      { joins(:region).order('region_name asc') }
  scope :preload_regions, ->      { includes(:region).order('regions.region_name asc') }
  scope :enabled,         ->      { where(enabled: true) }
  validates_uniqueness_of :account_id, scope: [:region_id]

  def reset_billable_service_stats(adapter_ids, potential_benefit_map)
    adapter_ids.each_with_object([]) do |adapter_id, memo|
      potential_benefit = potential_benefit_map[adapter_id][self.region_id]["total_benefit"] rescue 0.0
      memo << account.get_billable_service_status(adapter_id, self.region_id).merge(
        potential_benefit: potential_benefit)
    end
  end

  def get_value(a, attribute_value)
    case a.class::SERVICE_CLASS.to_s
    when 'Services::Compute::Server::AWS'
      return attribute_value
    when 'Services::Compute::Server::Volume::AWS'
      return attribute_value
    when 'Services::Database::Rds::AWS'
      return attribute_value        
    else
      return nil
    end
  end

  # def update_billable_service_stats(adapter_id)
  #   services_stats = Service.synced_services.where({
  #     adapter_id: adapter_id, region_id: self.region_id, type: Service::BILLABLE_SERVICES
  #     }).select(
  #       'type AS type,SUM("services"."cost_by_hour") AS sum_cost_by_hour,COUNT("services"."id") AS count'
  #     ).group(:type).collect{|a|
  #       {cost: a.sum_cost_by_hour,type: a.type,count: a.count}
  #     }.compact
  #   self.stats = self.stats.collect{|stat|
  #     (stat["services"] = services_stats) if stat["adapter_id"].eql?(adapter_id)
  #     stat
  #   }
  #   self.update_attribute(:billing_stats,stats)
  # end
end
