# frozen_string_literal: false

# Vmware Worker to upload files and Generate Cost
module VmWare
  class InventoryCostUploaderWorker

    include Sidekiq::Worker
    sidekiq_options queue: :metric, retry: false, backtrace: true
    attr_reader :account, :adapter, :vw_vcenter, :target_date
    attr_accessor :billing_config, :report_data
    BILLING_CONFIG_COLUMNS = %w[margin_cost discount_cost net_cost].freeze

    def perform(vcenter_id, target_date, metric_queue_change = false, is_monthly = false, report_data_id = nil)
      @report_data = ReportDataReprocessing.find_by(id: report_data_id)
      @vw_vcenter = VwVcenter.find_by(id: vcenter_id)
      @target_date = Date.parse(target_date.to_s)
      @adapter = vw_vcenter.adapter
      @account = adapter.account
      @billing_config = {}
      load_billing_configuration
      start_processing(metric_queue_change, is_monthly)
    end

    protected

    def load_billing_configuration
      config_params = {}.tap do |param|
        param[:billing_adapter_id] = adapter.id
        param[:month] = target_date.strftime('%Y-%m')
        param[:refresh_cache] = true
      end
      result = BillingConfigurationService.monthly_data(params: config_params)
      return if result.blank? || [500, 422].include?(result[:status])

      result = result.with_indifferent_access
      @billing_config = if result[:without_filter].present?
        result[:without_filter]
      elsif result[:with_filter] && result[:with_filter][vw_vcenter.id]
        result[:with_filter][vw_vcenter.id]
      else
        {}
      end
    end

    def start_processing(metric_queue_change, is_monthly)
      CSLogger.info "\n------ InventoryCostUploader::Process Started for VwVcenter: #{vw_vcenter.id} at #{st = Time.now} ------\n"
      CurrentAccount.client_db = account
      fileinfo = FileInfo.where(adapter_id: adapter.id, month: target_date.strftime('%Y-%m')).last
      if rate_card.blank?
        fileinfo.update(report_worker_status: 'failed', error_message: 'Missing RateCard') if fileinfo.present?
        report_data.update(status: 6, error_logs: 'Missing RateCard', end_time: Time.now.utc) if report_data.present?
        CSLogger.error "------ InventoryCostUploader::ProcessTerminated: Missing Missing RateCard ------\n"
        return
      end
      inventory_power_states = fetch_vw_inventory_power_states
      inventory_power_off_states = fetch_vw_inventory_power_off_states

      if inventory_power_states.blank?
        fileinfo.update(error_message: 'Missing InventoryPowerState Records') if fileinfo.present?
        report_data.update(error_logs: 'Missing InventoryPowerState Records', end_time: Time.now.utc) if report_data.present?
        CSLogger.error "------ InventoryCostUploader::ProcessTerminated: Missing InventoryPowerState Records ------\n"
        return
      end

      target_inventory_ids = inventory_power_states.keys
      target_inventories = fetch_vw_inventories(target_inventory_ids)
      power_off_inventories =  fetch_vw_inventories(inventory_power_off_states)
      if target_inventories.blank?
        fileinfo.update(error_message: 'Missing VwInventory Records') if fileinfo.present?
        report_data.update(error_logs: 'Missing VwInventory Records', end_time: Time.now.utc) if report_data.present?
        CSLogger.error "------ InventoryCostUploader::ProcessTerminated: Missing VwInventory Records ------\n"
        return
      end

      CSLogger.info "InventoryCostUploader::InventoryCount: #{target_inventories.length}"
      # CSLogger.info "\nInventoryCostUploader::RateCard\n\tOriginal: #{original_rate_card.inspect};\n\tApplied: #{rate_card.inspect}"
      CSLogger.info "\nInventoryCostUploader::RateCard\n\t Present: #{original_rate_card.present?};\n\tApplied: #{rate_card.present?}"
      CSLogger.info "\nInventoryCostUploader::FileContent generation started at #{t = Time.now}."
      csv_file_content = execute { generate_cost_details_csv(target_inventories, inventory_power_states, power_off_inventories) }
      CSLogger.info "InventoryCostUploader::FileContent generation completed within #{(Time.now - t).round(2)} seconds."
      if is_monthly
        if fileinfo.present? && (fileinfo.persisted? && fileinfo.report_worker_status.in?(['completed', 'failed', 'fetching', 'uploading']))
          fileinfo.report_worker_status = 'uploading'
          fileinfo.save
        else
          return
        end
      end
      report_data.update(status: 2) if report_data.present?

      execute(retry_enabled: true) do
        upload_to_s3(csv_file_content)
      end

      CSLogger.info "------ InventoryCostUploader::ProcessCompleted for adapter: #{adapter.id} VwVcenter: #{vw_vcenter.id} within #{(Time.now - st).round(2)} seconds. ------\n"
      fileinfo.update(report_worker_status: 'completed') if fileinfo.present? && is_monthly
      report_data.update(status: 5, end_time: Time.now.utc) if report_data.present? && is_monthly
    end

    def on_success(status, options)
      if options['is_regenerated']
        options['target_date'] = options['end_date']
        CSLogger.info "CsvToParquetGlueJobExecutorWorker: initiated for adapter: #{options['adapter_id']} and date: #{options['target_date']}"
        ::VmWare::CsvToParquetGlueJobExecutorWorker.set(queue: 'vmware_metric_regenerate').perform_async(options['vcenter_id'], options['target_date'], options)
      else
        date_array = (Date.parse(options['start_date'])..Date.parse(options['end_date'])).map {|d| d.strftime("%Y-%m")}.uniq
        date_array.each do |date|
          options['target_date'] = "#{date}-01"
          CSLogger.info "CsvToParquetGlueJobExecutorWorker: initiated for adapter: #{options['adapter_id']} and date: #{options['target_date']}"
          ::VmWare::CsvToParquetGlueJobExecutorWorker.perform_async(options['vcenter_id'], options['target_date'], options)
        end
      end
    end

    # This method currently not in use
    # def enqueue_csv_to_parquet_glue_job(metric_queue_change)
    #   if metric_queue_change
    #     batch.jobs { ::VmWare::CsvToParquetGlueJobExecutorWorker.set(queue: 'vmware_metric_regenerate').perform_async(vw_vcenter.id, target_date) }
    #   else
    #     batch.jobs { ::VmWare::CsvToParquetGlueJobExecutorWorker.perform_async(vw_vcenter.id, target_date) }
    #   end
    # end

    def execute(retry_enabled: false)
      retries = 1
      begin
        yield
      rescue StandardError => e
        if retry_enabled && (retries += 1) <= 3
          CSLogger.error "InventoryCostUploader::Error: #{e.message}; Next attempt(#{retries}) in 20 sec"
          sleep 20
          retry
        else
          if ENV['HONEYBADGER_API_KEY']
            Honeybadger.notify(e,
                               error_class: 'InventoryCostUploader',
                               error_message: e.message,
                               parameters: {
                                 account_id: account.id,
                                 vcenter_id: vw_vcenter.id,
                                 adapter_id: adapter.id,
                                 target_date: target_date
                               })
          end
          fileinfo = FileInfo.where(adapter_id: adapter.id, month: target_date.strftime('%Y-%m')).last
          fileinfo.update(report_worker_status: 'failed', error_message: e.message) if fileinfo.present?
          report_data.update(status: 6, error_logs: e.message, end_time: Time.now.utc) if report_data.present?
          CSLogger.error "------ InventoryCostUploader::ProcessTerminated: #{e.message} ------\n"
          CSLogger.error e.backtrace
          raise
        end
      end
    end

    def generate_cost_details_csv(inventories, power_states, power_off_inventories)
      categories = TagCategory.where(adapter_id: adapter.id)
      # categories_name_hash = categories.map { |a| [a.name,a.value]}.to_h
      categories_column = []
      if categories.present?
        begin
          vcenter_specific_categories = categories.group_by { |cat| cat.vcenter_id }[vw_vcenter.id] || []
          #vcenter_specific_categories_hash = Hash[vcenter_specific_categories.pluck(:name, :id).group_by(&:first).map{ |k,a| [k,a.map(&:last)] }]
          # categories_columnar_named_hash = vcenter_specific_categories.map { |a| [a.col_name,a.value]}.to_h rescue {}
          # categories_hash_reverse = categories.map { |a| [a.value,a.name]}.to_h
          categories_columnar_named = vcenter_specific_categories.map { |cat| [cat.col_name,cat.value]}
          categories_columnar_named_hash = categories_columnar_named.each_with_object(Hash.new { |cat_hash, cat_key| cat_hash[cat_key] = [] }) do |(col_name, value), hash|
            hash[col_name] << value
          end
          categories_column = categories.map(&:col_name).sort.uniq
        rescue StandardError => e
          if ENV['HONEYBADGER_API_KEY']
            Honeybadger.notify(e,
                               error_class: 'InventoryCostUploaderWorker',
                               error_message: e.message,
                               parameters: {
                                 account_id: account.id,
                                 vcenter_id: vw_vcenter.id,
                                 adapter_id: adapter.id,
                                 target_date: target_date
                               })
          end
        end
      end
      headers = %w[created_at adapter_id vcenter_id vcenter_name vcenter_provider_id resource_id resource_type resource_provider_id parent_id parent_type os_name tag uptime_hours resource_pool vm_commited_storage vm_uncommited_storage cost power_state guest_id guest_family cluster_name cpu_cors vm_memory datastore].concat(BILLING_CONFIG_COLUMNS).concat(%w[tags_data vm_disk_names vm_disk_data_names disk_cost disk_margin_cost disk_discount_cost net_disk_cost service_tier total_disk_size]).concat(categories_column)
      CSV.generate(headers: true) do |csv|
        csv << headers
        inventories.each do |inventory|
          data_on_array, data_on_array_memory, data_on_array_disk = get_inventory_data(inventory, power_states, categories_columnar_named_hash, categories_column, 'poweredOn', categories)
          csv << data_on_array_memory if inventory.vm?
          csv << data_on_array_disk if inventory.vm? && data_on_array_disk.present?
          csv << data_on_array
        end

        power_off_inventories.each do |inventory|
          data_off_array, data_off_array_memory, data_on_array_disk = get_inventory_data(inventory, power_states, categories_columnar_named_hash, categories_column, inventory.data['powerState'], categories)
          csv << data_off_array_memory if inventory.vm?
          csv << data_on_array_disk if inventory.vm? && data_on_array_disk.present?
          csv << data_off_array
        end
      end
    end

    def calculate_linked_disks_cost(inventory, power_states)
      version = inventory.vw_inventory_versions.where('created_at <= ?', target_date.end_of_day).order(created_at: :desc).first
      data_store_provider_ids = version.data['datastore'].pluck('value') rescue []
      disk_names = data_store_provider_ids.present? ? data_store_provider_ids.join(',') : ''
      data_stores = VwInventory.data_stores.where(vw_vcenter_id: inventory.vw_vcenter_id, provider_id: data_store_provider_ids)
      disks_cost = 0
      vm_disk_data_names = ''

      disk_size = nil
      if version.data['disks'].present?
        version.data['disks'].each do |disk|
          name = disk['name']
          size = disk['disk_size']
          datastore = disk['datastore_moid']
          datastore_hash = version.data['datastore'].select { |ds| ds["value"] == datastore }.first || {}
          vm_disk_data_names << "{ 'name':'#{name}', 'size':'#{size}', 'datastore': '#{datastore}', 'datastore_type': '#{datastore_hash['datastore_type']}', 'policy_name': '#{disk['storage_policy']}' },"
          data_store =  VwInventory.where(provider_id: disk['datastore_moid'], vw_vcenter_id: inventory.vw_vcenter_id).last
          disks_cost += get_total_uptime_and_cost(data_store, power_states[data_store.id],nil, size).last
        end
      end
      vm_disk_data_names = vm_disk_data_names.empty? ? '[]' : "[#{vm_disk_data_names.chop!}]"
      if data_stores.present? && !version.data['disks'].present?
        data_stores.each_with_index do |datastore, i|
          disks_cost += get_total_uptime_and_cost(datastore, power_states[datastore.id],nil, nil).last
        end
      end
      [disks_cost, disk_names, vm_disk_data_names]
    end

    def calculate_net_disk_cost(vm_disk_cost)
      margin = ((vm_disk_cost * billing_config[:margin_percentage].to_f) / 100).round(2)
      discount = ((vm_disk_cost * billing_config[:discount_percentage].to_f) / 100).round(2)
      net_disk_cost = (vm_disk_cost + margin - discount).round(2)
    end

    def fetch_tags_column_data(tag_values, categories_columnar_named_hash, categories_column)
      # For now TagNames::VmWare is not is use on cost.
      tag_data = []
      #tag_values = TagNames::VmWare.where(:tag_value.in => inventory_tags, :created_at.lte => target_date.end_of_day).pluck(:category_id, :name)
      tag_values = Hash[tag_values.group_by(&:first).map{ |k,a| [k,a.map(&:last)] }]
      categories_column.each do |tag|
        tags = categories_columnar_named_hash[tag].map { |cat_key| tag_values[cat_key] }.flatten.compact
        # tags = tag_values[categories_columnar_named_hash[tag]]
        tags = tags.present? ? "#{tags.join(',')}" : ''
        tag_data << tags
      end
      tag_data
    end

    def fetch_tags_data(inventory)
      inventory_tags = inventory.tags
      column_tag_values = ''
      TagNames::VmWare.where(:tag_value.in => inventory_tags, :created_at.lte => target_date.end_of_day).each do |tag|
        column_tag_values << "{ 'key':'#{tag.name}', 'value':'#{tag.tag_value}', 'category_id':'#{tag.category_id}' },"
      end
      column_tag_values.empty? ? '[]' : "[#{column_tag_values.chop!}]"
    end

    def fetch_billing_config_costs(total_cost)
      margin_cost = ((total_cost * billing_config[:margin_percentage].to_f) / 100).round(2)
      discount_cost = ((total_cost * billing_config[:discount_percentage].to_f) / 100).round(2)
      net_cost = (total_cost + margin_cost - discount_cost).round(2)
      {}.tap do |col|
        col[:margin_cost] = margin_cost
        col[:discount_cost] = discount_cost
        col[:net_cost] = net_cost
      end
    end

    def upload_to_s3(csv_file_content)
      aws_adapter = Adapters::AWS.get_default_adapter
      s3_client = AWSSdkWrappers::S3::Client.new(aws_adapter, APP_REGION).client
      s3 = Aws::S3::Resource.new({ name: RAW_REPORT_BUCKET, client: s3_client })
      obj = s3.bucket(RAW_REPORT_BUCKET).object(s3_file_path)
      CSLogger.info "InventoryCostUploader::DestinationFilePath: #{obj.key} for adapter: #{adapter.id}"
      CSLogger.info "InventoryCostUploader::FileUpload started at #{t = Time.now} for adapter: #{adapter.id}."
      obj.put(body: csv_file_content)
      CSLogger.info "InentoryCostUploader::FileUpload completed at: #{Time.now} ET: #{(Time.now - t).round(2)} seconds for adapter: #{adapter.id}."
    end

    def s3_file_path
      <<~FILE_PATH.squish.gsub(' ', '/')
        VMware
        #{org_identifier}
        #{adapter.id}
        year=#{target_date.year}
        month=#{target_date.month}
        day=#{target_date.day}
        #{target_file_name}
      FILE_PATH
    end

    def target_file_name
      <<~FILE_NAME.squish.gsub(' ', '')
        vcenter_
        #{vw_vcenter.id.split('-').last}_
        cost_details_
        #{target_date.to_s.underscore}.
        csv
      FILE_NAME
    end

    def today_version_time(inventory)
      time = []
      today_versions = inventory.vw_inventory_versions.where(created_at: (target_date.beginning_of_day..target_date.end_of_day)).order(created_at: :desc).pluck(:created_at)
      if today_versions.any?
        time << today_versions.reverse
        time.flatten!
      else
        []
      end
    end

    def get_total_uptime_and_cost(inventory, records, vm_type = nil, total_disk_size = nil)
      return [0,0] unless records.present?
      times = today_version_time(inventory)
      if times.blank?
        latest_version = inventory.vw_inventory_versions.where('created_at < ?', target_date.beginning_of_day).order(created_at: :desc).first
        get_uptime_and_cost(inventory, records&.count.to_i, latest_version, vm_type, total_disk_size)
      else
        result = []
        times.uniq!
        times.each_with_index do |time, i|
          if i==0
            version = inventory.vw_inventory_versions.where('created_at < ?', time).order(created_at: :desc).first
            version = inventory.vw_inventory_versions.where(created_at: time).last if version.blank?
            records_count = records.select { |rec| rec.created_at.to_i < time.to_i }.count
            result << get_uptime_and_cost(inventory, records_count, version, vm_type, total_disk_size)
          end
          end_time = times[i+1].present? ? times[i+1] : target_date.end_of_day
          version = inventory.vw_inventory_versions.where(created_at: time).first
          if times[i+1].present?
            records_count = records.select { |rec| rec.created_at.to_i >= time.to_i && rec.created_at.to_i < end_time.to_i}.count
          else
            records_count = records.select { |rec| rec.created_at.to_i >= time.to_i && rec.created_at.to_i <= end_time.to_i}.count
          end
          result << get_uptime_and_cost(inventory, records_count, version, vm_type, total_disk_size)
        end
        result.compact!
        result.count > 1 ? result.transpose.map(&:sum) : result.flatten
      end
    end

    def get_uptime_and_cost(inventory, no_of_records, version, vm_type, total_disk_size)
      return [0, 0] unless no_of_records.to_i.positive?
      total_uptime = no_of_records / VwInventoryPowerState::UPDATE_FREQUENCY_IN_HOUR.to_f
      total_cost = case inventory.resource_type
      when 'VirtualMachine'
        if vm_type == 'memory'
          get_vm_memory_cost(version, total_uptime)
        else
          get_vm_cpu_cost(version, total_uptime)
        end
      when 'Datastore'
        get_data_store_cost(inventory, total_uptime, version, total_disk_size)
      else
        0
      end
      [total_uptime, total_cost]
    end

    def get_vm_memory_cost(inventory, total_uptime)
      # cpu_cost = inventory.data['numCPU'].to_f * (rate_card.cpu * total_uptime)
      memory_cost = (inventory.data['memoryMB'].to_f / 1024) * (rate_card.memo_size * total_uptime)
      os_cost = 0 # TODO: calculate OS cost.
      return (memory_cost + os_cost)
    rescue StandardError => e
      if ENV['HONEYBADGER_API_KEY']
            Honeybadger.notify(e,
                               error_class: 'InventoryCostUploaderWorker',
                               error_message: e.message,
                               parameters: {
                                 account_id: account.id,
                                 vcenter_id: vw_vcenter.id,
                                 adapter_id: adapter.id,
                                 target_date: target_date
                               })
      end
      return 0
    end

    def get_vm_cpu_cost(inventory, total_uptime)
      cpu_cost = inventory.data['numCPU'].to_f * (rate_card.cpu * total_uptime)
      # memory_cost = (inventory.data['memoryMB'].to_f / 1024) * (rate_card.memo_size * total_uptime)
      os_cost = 0 # TODO: calculate OS cost.
      return (cpu_cost + os_cost)
      rescue StandardError => e
      if ENV['HONEYBADGER_API_KEY']
            Honeybadger.notify(e,
                               error_class: 'InventoryCostUploaderWorker',
                               error_message: e.message,
                               parameters: {
                                 account_id: account.id,
                                 vcenter_id: vw_vcenter.id,
                                 adapter_id: adapter.id,
                                 target_date: target_date
                               })
      end
      return 0
    end

    # This method not in use
    def get_virtual_machine_cost(inventory, total_uptime)
      cpu_cost = inventory.data['numCPU'].to_f * (rate_card.cpu * total_uptime)
      memory_cost = (inventory.data['memoryMB'].to_f / 1024) * (rate_card.memo_size * total_uptime)
      os_cost = 0 # TODO: calculate OS cost.
      return (cpu_cost + memory_cost + os_cost)
      rescue StandardError => e
      if ENV['HONEYBADGER_API_KEY']
        Honeybadger.notify(e,
                           error_class: 'InventoryCostUploaderWorker',
                           error_message: e.message,
                           parameters: {
                             account_id: account.id,
                             vcenter_id: vw_vcenter.id,
                             adapter_id: adapter.id,
                             target_date: target_date
                           })
      end
      return 0
    end

    def get_data_store_cost(inventory, total_uptime, version, total_disk_size)
      disk_size_rate = rate_card.disk_size
      rate_multipliers = rate_card.multipliers || []
      multiplier = rate_multipliers.detect do |multipl|
        (multipl['disk_providers_ids'] || []).include?(inventory.provider_id)
      end
      disk_size_rate *= (multiplier['rate'].to_f || 1.0) if multiplier
      if total_disk_size.present?
        return total_disk_size * (disk_size_rate * total_uptime)
      else
        return (version.data['capacityMB'].to_f / 1024) * (disk_size_rate * total_uptime)
      end
      rescue StandardError => e
      if ENV['HONEYBADGER_API_KEY']
            Honeybadger.notify(e,
                               error_class: 'InventoryCostUploaderWorker',
                               error_message: e.message,
                               parameters: {
                                 account_id: account.id,
                                 vcenter_id: vw_vcenter.id,
                                 adapter_id: adapter.id,
                                 target_date: target_date
                               })
      end
      return 0
    end

    def fetch_vw_inventories(inventory_ids)
      VwInventory
        .includes(:parent)
        .where(id: inventory_ids, vw_vcenter_id: vw_vcenter.id)
    end

    def fetch_vw_inventory_power_states
      VwInventoryPowerState.powered_on.where(
        vcenter_id: vw_vcenter.id,
        created_at: (target_date.beginning_of_day..target_date.end_of_day)
      ).group_by(&:inventory_id)
    end

    def fetch_vw_inventory_power_off_states
      VwInventoryPowerState.where(
        vcenter_id: vw_vcenter.id,
        created_at: (target_date.beginning_of_day..target_date.end_of_day)
      ).group_by(&:inventory_id).each_with_object([]) do |(inventory_id, group), power_off_inv|
        power_off_inv << inventory_id unless group.any? { |item| item.power_state == 'poweredOn' }
      end
    end

    def rate_card
      @rate_card ||= original_rate_card.try(:in_hour, target_date)
    end

    def original_rate_card
      rate_card = VmWareRateCard.where(account_id: account.id, adapter_id: adapter.id).last
      return_condition = (target_date.strftime('%Y-%m') == Date.today.strftime('%Y-%m')) || !rate_card.present?
      return rate_card if return_condition

      rate_card.fetch_rate_card_version(target_date)
    end

    def org_identifier
      account.organisation.organisation_identifier
    end

    def get_inventory_data(inventory, power_states, categories_columnar_named_hash, categories_column, power_state, categories)
      vm_disk_cost = 0
      vm_disk_names = ' '
      vm_disk_data_names = ''
      version = inventory.vw_inventory_versions.where('created_at <= ?', target_date.end_of_day).order(created_at: :desc).first
      if inventory.vm?
        vm_disk_cost, disk_names, vm_disk_data_names = calculate_linked_disks_cost(inventory, power_states)
        vm_disk_names = "#{inventory.provider_id}(#{disk_names})"
      end
      billing_config_disk_cost = { disk_margin_cost: 0.0, disk_discount_cost: 0.0, net_disk_cost: 0.0 }
      service_tier = inventory.vm? ? 'CPU' : 'Storage'

      tags_data = [] #fetch_tags_data(inventory)
      tag_values = []
      inventory_tag_values = get_inventory_tag_values(categories, inventory)

      # inventory_tag_values = categories.where(:created_at.lte => target_date.end_of_day).pluck(:children).flatten.compact.select{|c| inventory_tags.include?(c[:id]) }
      inventory_tag_values.each { |tag_value| tag_values << [tag_value['categoryId'], tag_value['name']] }
      tags_column_data = fetch_tags_column_data(tag_values, categories_columnar_named_hash, categories_column)
      parent_inventory = inventory.parent
      if power_state == 'poweredOn'
        if inventory.vm?
          uptime_hours, total_cost = get_total_uptime_and_cost(inventory, power_states[inventory.id], 'cpu')
          uptime_hours, total_cost_memory = get_total_uptime_and_cost(inventory, power_states[inventory.id], 'memory')
          billing_config_disk_cost = fetch_billing_config_costs(vm_disk_cost)
          billing_config_costs = fetch_billing_config_costs(total_cost)
          billing_config_memory_costs = fetch_billing_config_costs(total_cost_memory)
        else
          uptime_hours, total_cost = get_total_uptime_and_cost(inventory, power_states[inventory.id])
          billing_config_costs = fetch_billing_config_costs(total_cost)
        end
      else
        total_cost_memory = uptime_hours = total_cost = vm_disk_cost = 0
        billing_config_costs = billing_config_memory_costs = { margin_cost: 0, discount_cost: 0, net_cost: 0 }
      end
      data_disk_array = nil
      power_state = '' if inventory.data_store?
      data_array = [
        target_date, # created_at
        adapter.id, # adapter_id
        vw_vcenter.id, # vcenter_id
        vw_vcenter.fqdn || vw_vcenter.name, # vcenter_name
        vw_vcenter.provider_id, # vcenter_provider_id
        inventory.id, # resource_id
        inventory.resource_type, # resource_type
        inventory.provider_id, # resource_provider_id
        parent_inventory.try(:provider_id), # parent_id
        parent_inventory.try(:resource_type), # parent_type
        inventory.data.dig('guest', 'guestFullName'), # os_name
        inventory.tag, # tag
        uptime_hours, # uptime_hours
        inventory.data['resourcePool'], #resource_pool
        inventory.data['vmCommittedStorage'], #vm_commited_storage
        inventory.data['vmUnCommittedStorage'], #vm_uncommited_storage
        total_cost, # cost
        power_state, # power_state
        inventory.data.dig('guest', 'guestId'), # guest_id
        inventory.data.dig('guest', 'guestFamily'), # guest_family
        inventory.vm_cluster&.tag, #cluster_name
        version.data['numCPU'].to_f, # cpu_cors
        version.data['memoryMB'].to_f, # vm_memory
        version.data['capacityMB'].to_f # datastore
      ]
      if inventory.vm?
        data_array_memory = data_array.dup
        data_array_memory[-8] = total_cost_memory
        data_array_memory = data_array_memory.concat(billing_config_memory_costs.values).concat(["#{tags_data}", vm_disk_names, vm_disk_data_names, vm_disk_cost, billing_config_disk_cost.values, 'Memory', 0].flatten).concat(tags_column_data)
        if version.data['disks'].present? && vm_disk_cost.present?
          data_disk_array = data_array.dup
          data_disk_array[-8] = vm_disk_cost
          data_disk_array = data_disk_array.concat(billing_config_disk_cost.values).concat(["#{tags_data}", vm_disk_names, vm_disk_data_names, 0, [0, 0, 0], 'Disk', version.data['total_disk_size']].flatten).concat(tags_column_data)
        end
      end
      data_array = data_array.concat(billing_config_costs.values).concat(["#{tags_data}", vm_disk_names, vm_disk_data_names , 0, [0, 0, 0], service_tier, 0].flatten).concat(tags_column_data)
      [data_array, data_array_memory, data_disk_array]
    end

    def fetch_inventory_tags(inventory)
      version = inventory.vw_inventory_versions.where('created_at < ?', target_date.end_of_day).order(created_at: :desc).first
      version.present? ? version.data['tags'] : inventory.tags
    end

    def get_inventory_tag_values(categories, inventory)
      inventory_tags =  fetch_inventory_tags(inventory) #inventory.tags
      tag_category_children = {}
      category_ids = categories.pluck(:id)
      all_versions = Version.where(:versionable_id.in => category_ids).where(:created_at.lte => target_date.end_of_day).order(created_at: :desc).group_by(&:versionable_id)

      categories.each do |category|
        latest_version = all_versions[category.id]&.first

        tag_category_children[category.id] = if latest_version
                                              latest_version.try(:children) || []
                                            else
                                              category.try(:children) || []
                                            end
      end
      tag_category_children.values.flatten.compact.select{|c| inventory_tags.include?(c[:id]) }
    end

  end
end