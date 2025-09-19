class Costs::Searcher < CloudStreetService
  attr_reader :account, :type, :from_date, :to_date, :date_range, :interval, :filters, :group_by, :group_ids, :cost_detail_type

  ALLOWED_FILTERS      = [:adapter_id, :application_id, :environment_id, :service_id]
  SUPPORTED_INTERVALS  = %w(daily monthly)
  SUPPORTED_COST_TYPES = %w(blended_cost unblended_cost)

  GROUP_NAME_TO_COLUMN_NAME = {
    "Adapter" => 'adapter_id',
    "Application" => 'service_id',
    "Environment" => 'environment_id',
    "Service" => 'service_id',
    "ServiceCategory" => 'service_id'
  }
  SUPPORTED_RESOURCE_TYPES = ["Amazon Elastic Compute Cloud", "Amazon RDS Service"]

  def initialize(account, params)
    @account = account

    @type        = params[:type]
    @from_date   = params[:from_date]
    @to_date     = params[:to_date]
    @interval    = params[:interval] || 'daily'
    @date_range  = (from_date .. to_date) if date_specified?
    @filters     = params[:filters].slice(ALLOWED_FILTERS) if params[:filters].present?
    @group_by    = params[:group_by]
    @group_ids   = params[:group_ids]
    @cost_detail_type = params[:cost_detail_type] || 'blended_cost'
  end

  def search(&block)
    return unless params_are_valid(&block)
    result_map = execute_searching(group_filter: date_filter, &block)
    return if result_map.blank?

    self.class.status Status, :success, result_map, &block
  end

  def cost_by_service(&block)
    query_map = { account_id: account.id }
    if group_by.present? && group_ids.present?
      filter_name, filter_value = Cost.get_filter_name_n_value(account, group_ids: group_ids, group_by: group_by)
      query_map.merge!(filter_name => filter_value)
    end
    query_map.merge!(date: date_range) if date_specified?

    result = Cost.get_rounded_cost_by_service(query_map)

    top_services_json = Cost.get_top_services_for_each_category(account, date_range: date_range, group_by: group_by, group_ids: group_ids, cost_detail_type: cost_detail_type, uniq_resource_types: result.keys)

    result_hash = { statistics: result, top_services: top_services_json }
    self.class.status Status, :success, result_hash, &block
    result_hash
  end

  private

  def date_specified?
    from_date.present? && to_date.present?
  end

  def params_are_valid(&block)
    if (error_map = params_are_not_valid)
      self.class.status Status, :error, error_map, &block
      false
    else
      true
    end
  end

  def execute_searching(group_filter:, &block)
    filtered_cost_query = prepare_filter_query rescue nil
    unless filtered_cost_query
      self.class.status Status, :error, {filters: ['are not valid']}, &block
      return
    end

    filters_column_name = GROUP_NAME_TO_COLUMN_NAME[group_by]
    filter_id_map = updated_filter_ids

    group_ids.inject({}) do |costs_map, id|
      query = filtered_cost_query.where(filters_column_name => filter_id_map[id]).group(group_filter)
      query = query.order(date_filter) if date_specified?
      costs_map[id] = query.sum(cost_detail_type)
      costs_map
    end
  end

  def prepare_filter_query
    filtered_cost_query = Cost.where({account_id: account.id})
    if filters.present?
      filtered_cost_query = filtered_cost_query.where(filters.except(:application_id))
      filtered_cost_query = filter_by_application(filtered_cost_query) if filters[:application_id].present?
    end
    filtered_cost_query = apply_date_filter(filtered_cost_query) if date_range.present?
    filtered_cost_query
  end

  def apply_date_filter(query)
    query.where(date: date_range)
  end

  def date_filter
    if is_interval_daily?
      :date
    else
      "date_trunc('month', date)"
    end
  end

  def filter_by_application(query)
    service_ids = account.services.by_application(filters[:application_id]).pluck(:id).uniq
    query.where(service_id: service_ids)
  end

  def updated_filter_ids
    if group_by == 'Application'
      group_ids.inject({}) { |h, app_id| h[app_id] = account.services.by_application(app_id).pluck(:id).uniq; h }
    elsif group_by == 'ServiceCategory'
      group_ids.inject({}) { |h, service_type| h[app_id] = account.services.where(type: service_type).pluck(:id).uniq; h }
    else
      group_ids.inject({}) { |h, id| h[id] = id; h }
    end
  end

  def params_are_not_valid
    error_map = {}

    # these fields must be specified
    [:group_by, :cost_detail_type, :group_ids].each do |key|
      if self.send(key).blank?
        add_error(error_map, key, 'please specify')
      end
    end

    # cost_detail_type's value must be valid
    if cost_detail_type.present? && SUPPORTED_COST_TYPES.exclude?(cost_detail_type)
      add_error(error_map, :cost_detail_type, 'is not supported')
    end

    # interval's value must be valid
    if interval.present? && SUPPORTED_INTERVALS.exclude?(interval)
      add_error(error_map, :interval, 'is not supported')
    end

    # group_by's value must be valid
    if group_by.present? && GROUP_NAME_TO_COLUMN_NAME.keys.exclude?(group_by)
      add_error(error_map, :group_by, 'is not supported')
    end

    error_map.present? ? error_map : false
  end

  def add_error(error_map, key, msg)
    error_map[key] ||= []
    error_map[key] << msg
  end

  # obvious mathods

  def is_interval_daily?
    interval == 'daily'
  end
end
