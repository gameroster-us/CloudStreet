require 'csv'
class GenerateVmWareServiceManagerCsvWorker
  include Sidekiq::Worker
  sidekiq_options queue: :download_cost_report, retry: false, backtrace: true

  def perform(params)
    params = params.with_indifferent_access
    account = Account.find(params[:account_id])
    tenant = Tenant.find(params[:tenant_id])
    params[:download_csv] = true
    relations = ServiceManagerService.vm_ware_services_details(tenant, params, account)

    relations = relations.order(updated_at: :desc)
    result = []
    relations.each do |relation|
      r_hash = {}
      r_hash[:vcenter_name] = relation.vw_vcenter.data['name']
      r_hash[:service_name] = relation.tag
      r_hash[:provider_id] = relation.provider_id
      r_hash[:service_type] = relation.resource_type
      r_hash[:adapter_name] = relation.vw_vcenter.adapter&.name
      if relation.vm?
        r_hash[:cluster_name] = relation.vm_cluster&.tag
        r_hash[:state] = relation.data['powerState']
        r_hash[:guest_full_name] = relation.data['guest']['guestFullName']
        r_hash[:guest_id] = relation.data['guest']['guestId']
        r_hash[:guest_family] = relation.data['guest']['guestFamily']
        r_hash[:cores] = relation.data['numCPU']
        r_hash[:memory] = relation.data['memoryMB']
      elsif relation.data_store?
        r_hash[:cluster_name] = "#{relation.parent.tag} (#{relation.parent.provider_id})" if relation.parent&.data_center?
        r_hash[:free_space] = relation.data['freeSpaceMB']
        r_hash[:total_capacity] = relation.data['capacityMB']
      end
      r_hash[:monthly_estimated_cost] = (relation.cost_by_hour * 24 * 30).to_f rescue 0
      r_hash[:daily_estimated_cost] = (relation.cost_by_hour * 24).to_f rescue 0
      result << r_hash
    end

    file_path = generate_and_upload_csv_file(result, params)
    CSLogger.info "file path--#{file_path}"
    send_notification(file_path.to_s.split('/').last, account, params[:auth_token], params[:user_id])
  end

  def generate_and_upload_csv_file(result, params)
    report_name = 'cloudstreet_vm_ware_service_manager_report'
    file_path = "#{Rails.root}/public/service_manager/#{report_name}--#{Time.now.utc.strftime('%Y-%m-%d--%H-%M-%S')}.csv"
    CSV.open(file_path, 'w') do |csv|
      csv << ['FILTERS'] if params[:adapter_group_id].present? || params[:name].present? || (params[:tags].present? && !params['tags'].eql?('[]'))
      csv << ['Adapter Group', "#{ServiceGroup.find(params[:adapter_group_id]).try(:name)}"] if params[:adapter_group_id].present?
      csv << ['Name/ProviderID', "#{params[:name]}"] if params[:name].present?
      if params[:tags].present? && !params['tags'].eql?('[]')
        tag_join_symbol = (params[:tag_operator].present? && params[:tag_operator].eql?('AND')) ? '&&' : '||'
        tags = JSON.parse(params[:tags])
        csv << ['Tags', "#{tags.map{ |tag| tag['tag_key'] + tag['tag_sign'] + tag['tag_value'] }.join(" #{tag_join_symbol} ") }"]
      end
      if params[:tag_operator].present?
        tag_operator = params[:tag_operator].eql?('AND') ? '&& (AND)' : '|| (OR)'
        csv << ['Tag Operator', "#{tag_operator}"]
      end

      csv << []
      header = result.first.keys
      csv << header.flatten.map do |col_name|
                header_mapping[col_name.to_sym]
              end
      result.each do |res|
        csv << res.values.map { |val| val.blank? ? 'N/A' : val }
      end
    end
    file_path
  end

  def send_notification(file_name, account, auth_token, user_id)
    options = {
      file_name: file_name,
      acc_id: account.id,
      user_id: user_id,
      subdomain: account.organisation.try(:subdomain),
      auth_token: auth_token,
      status: file_name.present? ? 'success' : 'failed'
    }
    NodeManager.send_form_data('notifications/download_report', options)
  end

  def header_mapping
    {
      'vcenter_name': 'vCenter',
      'service_name': 'Service Name',
      'adapter_name': 'Adapter',
      'provider_id': 'Service ID',
      'state': 'State',
      'service_type': 'Service Type',
      'cluster_name': 'Data Center (Cluster Name)',
      'daily_estimated_cost': 'DEC ($)',
      'monthly_estimated_cost': 'MEC ($)',
      'memory': 'Memory (MB)',
      'guest_full_name': 'Guest OS Full Name',
      'guest_id': 'Guest OS ID',
      'guest_family': 'Guest OS Family',
      'total_capacity': 'Disk Capacity (MB)',
      'free_space': 'Free Space',
      'cores': 'vCores',
      '': 'N/A'
    }
  end
end