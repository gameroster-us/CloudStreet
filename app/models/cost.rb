class Cost < ApplicationRecord
  DEFAULT_TOP_SERVICE_COUNT = 5

  belongs_to :account
  belongs_to :environment
  belongs_to :service
  belongs_to :adapter

  scope :environment_id_present, -> { where.not(environment_id: nil) }
  scope :in_month, ->(date_obj) { where(date: (date_obj.at_beginning_of_month .. date_obj.at_end_of_month)) }
  scope :get_cost_by_service, ->(map) { where(map).group(:resource_type).sum(:blended_cost) }

  class << self
    def get_rounded_cost_by_service(map)
      get_cost_by_service(map).inject({}) do |final_map, (type, sum)|
        rounded_value = sum.round(2)
        final_map[type] = rounded_value unless rounded_value.zero?
        final_map
      end
    end

    def get_top_services_for_each_category(account, options)
      filter_name, filter_value = get_filter_name_n_value(account, options.slice(:group_ids, :group_by))
      query_map = { filter_name => filter_value, account_id: account.id }.compact
      query = self.where(query_map).where.not(service_id: nil)
      query = query.where(date: options[:date_range]) if options[:date_range].present?

      result_map = options[:uniq_resource_types].inject({}) do |result_map, resource_type|
        result_map[resource_type] = query.where(resource_type: resource_type).order('sum_blended_cost DESC').limit(DEFAULT_TOP_SERVICE_COUNT).group(:service_id).sum(:blended_cost)
        result_map
      end

      # reference http://stackoverflow.com/questions/1124603/grouped-limit-in-postgresql-show-the-first-n-rows-for-each-group
      # raw_sql = "SELECT DISTINCT x.\"service_id\", x.\"resource_type\", x.\"row_no\" FROM ( SELECT ROW_NUMBER() OVER (PARTITION BY resource_type ORDER BY blended_cost DESC ) AS row_no, t.* FROM costs t #{query.where_sql.gsub('"costs"', 't')} AND t.service_id IS NOT NULL) x WHERE x.row_no <= 5;"
      # result_map = ActiveRecord::Base.connection.execute(raw_sql).to_a

      format_top_services(result_map)
    end

    def get_filter_name_n_value(account, group_ids:, group_by:)
      case group_by
      when 'Adapter'
        ['adapter_id', group_ids]
      when 'Application'
        service_id_arr = group_ids.inject([]) { |service_id_arr, app_id| service_id_arr << account.services.by_application(app_id).pluck(:id) }
        ['service_id', service_id_arr.uniq]
      when 'Environment'
        ['environment_id', group_ids]
      when 'Service'
        ['service_id', group_ids]
      when 'ServiceCategory'
        service_id_arr = account.services.where(type: group_ids).pluck(:id)
        ['service_id', service_id_arr]
      end
    end

    # service_map structure: { 'resource_type' => { 'service_id' => belnded_cost_sum, ...total 5 iteam }... for all resource_type }
    def format_top_services(service_map)
      service_ids = service_map.values.map { |h| h.keys }.uniq.flatten
      services_map = Service.get_service_id_map(service_ids) # services_map = {service_id: {service_attrs}, ...}

      service_map.inject({}) do |json, (resource_type, top_service_map)|
        json[resource_type] ||= []
        top_service_map.each do |service_id, cost|
          service = services_map[service_id]
          json[resource_type] << { name: service.name, id: service.id, cost: cost } if service
        end
        json
      end
    end
  end
end
