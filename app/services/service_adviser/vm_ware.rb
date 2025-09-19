# frozen_string_literal: true

class ServiceAdviser::VmWare < CloudStreetService
  class << self
    def list_service_type_with_count(filters, account, tenant, _user, current_tenant_currency_rates, &block)
      response_array = []
      filters = compact_filters(filters, tenant, account)

      %w[idle_vm idle_stopped_vm idle_disks rightsized_vm].each do |method_name|
        if filters[:service_type].blank? || filters[:service_type].eql?(method_name)
          result = public_send(method_name, filters, true)
        end
        response_array << { type: method_name, count: result[:count], cost_sum: result[:cost_sum]* 24 * 30 } if result.present? && result[:count].positive?
      end

      return response_array unless block_given?

      response = { service_type_count: response_array, assignable_environments: [] }
      status Status, :success, response, &block
    rescue Exception => e
      status Status, :error, e, &block
    end

    def list_service_type_with_detail(filters, paginate, sort, account, tenant, _user, &block)
      %i[service_type].each { |key| raise ActionController::ParameterMissing, key unless filters[key] }

      filters = compact_filters(filters, tenant, account)
      services = case filters[:service_type]
                 when 'idle_vm' then idle_vm(filters, false, false, sort, paginate)
                 when 'idle_stopped_vm' then idle_stopped_vm(filters, false, false, sort, paginate)
                 when 'rightsized_vm' then rightsized_vm(filters, false, false, sort, paginate)
                 when 'idle_disks' then idle_disks(filters, false, false, sort, paginate)
                 end

      total_service_count = services.blank? ? 0 : (paginate.present? ? services.total_entries : services.count)

      response = { total_service_count: total_service_count, services: services }
      status Status, :success, response, &block
    rescue Exception => e
      status Status, :error, e, &block
    end

    def idle_vm(filters, only_count = false, summary_data = false, sort = nil, paginate = {})
      services = default_services(filters).idle_instances.running_vms
      services = services.fetch_with_tags(filters[:tags], (filters[:tag_operator] || "OR"), filters[:account]) if filters[:tags].present?
      formatted_response(services, only_count, summary_data, sort, paginate)
    end

    def rightsized_vm(filters, only_count = false, summary_data = false, sort = nil, paginate = {})
      services = default_services(filters).vms.rightsized.running_vms
      services = services.fetch_with_tags(filters[:tags], (filters[:tag_operator] || "OR"), filters[:account]) if filters[:tags].present?
      formatted_response(services, only_count, summary_data, sort, paginate)
    end

    def idle_disks(filters, only_count = false, summary_data = false, sort = nil, paginate = {})
      services = default_services(filters).idle_instances.data_stores
      services = services.fetch_with_tags(filters[:tags], (filters[:tag_operator] || "OR"), filters[:account]) if filters[:tags].present?
      formatted_response(services, only_count, summary_data, sort, paginate)
    end

    def idle_stopped_vm(filters, only_count = false, summary_data = false, sort = nil, paginate = {})
      services = default_services(filters).idle_instances.stopped_vms
      services = services.fetch_with_tags(filters[:tags], (filters[:tag_operator] || "OR"), filters[:account]) if filters[:tags].present?
      formatted_response(services, only_count, summary_data, sort, paginate)
    end

    def formatted_response(services, only_count = false, summary_data = false, sort = nil, paginate = {})
      return { count: services.count, cost_sum: services.sum(:cost_by_hour) } if only_count

      if summary_data
        services.group_by { |a| a.vw_vcenter.adapter_id }.map do |adapter_id, records|
          { adapter_id: adapter_id, count: records.count, cost_sum: records.inject(0) { |sum, s| sum + s.cost_by_hour unless s.cost_by_hour.blank? } }
        end
      else
        sort_idle_services(services, sort, paginate)
      end
    end

    def default_services(filters)
      where_clause = { vw_vcenters: { adapter_id: filters[:adapter_id] } }
      where_clause[:vw_vcenters][:id] = filters[:vcenter_id] if filters[:vcenter_id].present?
      VwInventory.non_terminated.includes(:vw_vcenter).where(where_clause)
    end

    def recommended_csv(result, service_type, _current_account)
      CSV.generate(headers: true) do |csv|
        csv << fetch_csv_headers(service_type)
        begin
          result[:services].each do |record|
            csv << fetch_csv_data(record, service_type)
          end
        rescue Exception => e
          CSLogger.error "Error while downloading vmware csv: #{e.message}"
        end
      end
    end

    def compact_filters(filters, tenant, account)
      filters = filters.keep_if { |h| !filters[h].blank? }
      filters[:adapter_id] ||= tenant.adapters.normal_adapters.available.vm_ware_adapter.ids
      filters[:vcenter_id] = if filters[:vcenter_id].present?
        filters[:vcenter_id].split(',')
      else
        tenant.vw_vcenters
      end
      if filters[:tags].present?
        filters[:account] = account
        filters[:tags].map { |s| s["tag_value"] = nil if s["tag_value"].eql?("") }
      end
      filters
    end

    def sort_idle_services(services, sort, paginate)
      if sort.present?
        sort.downcase!
        services = if sort.include?('tag')
                     sort.include?('asc') ? services.order(tag: :asc) : services.order(tag: :desc)
                   elsif sort.include?('provider_id')
                     sort.include?('asc') ? services.order(provider_id: :asc) : services.order(provider_id: :desc)
                   elsif sort.include?('days_old')
                     sort.include?('desc') ? services.order(created_at: :asc) : services.order(created_at: :desc)
                   else
                     sort.include?('asc') ? services.order(created_at: :asc) : services.order(created_at: :desc)
                   end
      end
      services = services.paginate(paginate) if paginate.present?
      services
    end

    private

    def fetch_csv_headers(service_type)
      case service_type
      when 'idle_disks'
        ['vCenter Id', 'vCenter Name', 'Service Name', 'Service ID', 'Service Type', 'Data Center Name', 'Total Capacity (MB)', 'Free Space (MB)', 'Days old']
      when 'idle_stopped_vm', 'idle_vm'
        ['vCenter Id', 'vCenter Name', 'Service Name', 'Service ID', 'Cluster Name', 'Service Type', 'State', 'vCores', 'Memory (MB)', 'Days old', 'MEC']
      when 'rightsized_vm'
        ['vCenter Id', 'vCenter Name', 'Service Name', 'Service ID', 'Cluster Name', 'Service Type', 'State', 'vCores', 'Memory (MB)',
        'Days old', 'Recommended Memory (MB)', 'Recommend CPU', 'MEC']
      end
    end

    def fetch_csv_data(record, service_type)
      case service_type
      when 'idle_disks'
        [
          record.vcenter_id, record.vcenter_name, record.name, record.provider_id, record.service_type,
          record.additional_information.data_center_name,
          record.additional_information.total_capacity,
          record.additional_information.free_space, record.days_old
        ]
      when 'idle_stopped_vm', 'idle_vm'
        [
          record.vcenter_id, record.vcenter_name, record.name, record.provider_id, record.additional_information&.cluster_name, record.service_type, record.state,
          record.additional_information&.cores, record.additional_information.ram, record.days_old, record.monthly_estimated_cost.try(:round, 2)
        ]
      when 'rightsized_vm'
        [
          record.vcenter_id, record.vcenter_name, record.name, record.provider_id, record.additional_information&.cluster_name, record.service_type, record.state,
          record.additional_information&.cores, record.additional_information.ram, record.days_old,
          record.rightsize_information.mem_to_reclaim || record.rightsize_information.mem_to_add,
          record.rightsize_information.cpu_to_reclaim || record.rightsize_information.cpu_to_add,
          record.monthly_estimated_cost.try(:round, 2)
        ]
      end
    end
  end
end
