class ComplianceReportService < CloudStreetService
  extend CommonServiceHelper

  SERVICE_TYPES_MAP = {
    'Services::Network::SecurityGroup::AWS' => 'Security Group',
    'Services::Database::Rds::AWS' => 'RDS',
    'Storages::AWS' => 'S3',
    'Services::Compute::Server::AWS' => 'EC2',
    'Services::Compute::Server::Volume::AWS' => 'EBS Volume',
    'MachineImage' => 'AMI',
    'Services::Network::LoadBalancer::AWS' => 'Load Balancer',
    'Services::Network::AutoScaling::AWS' => 'AutoScaling',
    'Services::Network::AutoScalingConfiguration::AWS' => 'AutoScaling Configuration',
    'Vpcs::AWS' => 'VPC',
    'InternetGateways::AWS' => 'Internet Gateway',
    'IamUser' => 'IAM',
    'Services::Network::NetworkInterface::AWS' => 'Network Interface',
    'Resources::KeyPair' => 'Key Pair',
    'IamCertificate' => 'IAM Certificate',
    'AWSOrganisation' => 'Aws Organisation',
    'EncryptionKey' => 'Key Management',
    'CloudWatch' => 'CloudWatch Logs',
    'AWSTrail' => 'Aws CloudTrail',
    'AWSAccount' => 'AWS Account',
    'AWSConfig' => 'AWS Config',
    'IamGroup' => 'IAM Group'
  }.freeze

  class << self

    def security_trends(_current_account, current_tenant, params, &block)
      response_flag      = false
      categories         = []
      tenant_adapter_ids = current_tenant.adapters.aws_normal_active_adapters.pluck(:id)
      adapter_ids        = adapter_ids_from_filters(params, current_tenant)
      
      compliance_trends = ComplianceTrend.where(:adapter_id.in => adapter_ids)
      
      start_date = params['compliance_report']['start_date'].to_date
      end_date = params['compliance_report']['end_date'].to_date
      date_range = (start_date..end_date).to_a
      compliance_trends = compliance_trends.where(:date.in => date_range)

      cis_percentage, pci_percentage, nist_percentage, hipaa_percentage, awswa_percentage, overall_progress = [], [], [], [], [], []

      if params['monthly']
        month_series = date_range.map { |dr| dr.strftime('%b %y') }.uniq

        month_series.each do |month|
          categories << { label: month }
          selected_compliance_trends = compliance_trends.select { |trend| trend.date.strftime('%b %y') == month }
          if selected_compliance_trends.blank?
            cis_percentage << { value: 0 }
            pci_percentage << { value: 0 }
            nist_percentage << { value: 0 }
            hipaa_percentage << { value: 0 }
            awswa_percentage << { value: 0 }
            overall_progress << { label: month, value: 0 }
          else
            response_flag = true
            cis_compliance = selected_compliance_trends.select { |compliance_trend| compliance_trend.standard_type == 'CIS' }
            pci_compliance = selected_compliance_trends.select { |compliance_trend| compliance_trend.standard_type == 'PCI' }
            nist_compliance = selected_compliance_trends.select { |compliance_trend| compliance_trend.standard_type == 'NIST' }
            hipaa_compliance = selected_compliance_trends.select { |compliance_trend| compliance_trend.standard_type == 'HIPAA' }
            awswa_compliance = selected_compliance_trends.select { |compliance_trend| compliance_trend.standard_type == 'AWSWA' }

            compliance = {
              cis_percentage: cis_compliance,
              pci_percentage: pci_compliance,
              nist_percentage: nist_compliance,
              hipaa_percentage: hipaa_compliance,
              awswa_percentage: awswa_compliance,
              overall_progress: selected_compliance_trends
            }

            compliance.each do |pct, record|
              record.group_by { |ct| ct.date.strftime('%b %y') }.each do |month, object|
                threat_count_sum = if params[:adapter].blank?
                                     object.map(&:threat_count).min
                                   else
                                     object.map(&:threat_count).sum
                                   end
                total_threat_sum = if params[:adapter].blank?
                                     object.map(&:total_count).min
                                   else
                                     object.map(&:total_count).sum
                                   end
                if pct.to_s.eql?('cis_percentage')
                  cis_percentage << { value: ((threat_count_sum * 100) / total_threat_sum) }
                elsif pct.to_s.eql?('pci_percentage')
                  pci_percentage << { value: ((threat_count_sum * 100) / total_threat_sum) }
                elsif pct.to_s.eql?('nist_percentage')
                  nist_percentage << { value: ((threat_count_sum * 100) / total_threat_sum) }
                elsif pct.to_s.eql?('hipaa_percentage')
                  hipaa_percentage << { value: ((threat_count_sum * 100) / total_threat_sum) }
                elsif pct.to_s.eql?('awswa_percentage')
                  awswa_percentage << { value: ((threat_count_sum * 100) / total_threat_sum) }
                elsif pct.to_s.eql?('overall_progress')
                  overall_percentage = (cis_percentage[-1][:value] + pci_percentage[-1][:value] + nist_percentage[-1][:value] + hipaa_percentage[-1][:value] + awswa_percentage[-1][:value]) / 5
                  overall_progress << { label: month, value: overall_percentage.ceil }
                end
              end
            end
          end
        end
      else
        date_range.each do |date|
          categories << { label: date }
          selected_compliance_trends = compliance_trends.select { |trend| trend.date == date }
          if selected_compliance_trends.blank?
            cis_percentage << { value: 0 }
            pci_percentage << { value: 0 }
            nist_percentage << { value: 0 }
            hipaa_percentage << { value: 0 }
            awswa_percentage << { value: 0 }
            overall_progress << { label: date, value: 0 }
          else
            response_flag = true
            cis_compliance = selected_compliance_trends.select { |compliance_trend| compliance_trend.standard_type == 'CIS' }
            pci_compliance = selected_compliance_trends.select { |compliance_trend| compliance_trend.standard_type == 'PCI' }
            nist_compliance = selected_compliance_trends.select { |compliance_trend| compliance_trend.standard_type == 'NIST' }
            hipaa_compliance = selected_compliance_trends.select { |compliance_trend| compliance_trend.standard_type == 'HIPAA' }
            awswa_compliance = selected_compliance_trends.select { |compliance_trend| compliance_trend.standard_type == 'AWSWA' }

            compliance = {
              cis_percentage: cis_compliance,
              pci_percentage: pci_compliance,
              nist_percentage: nist_compliance,
              hipaa_percentage: hipaa_compliance,
              awswa_percentage: awswa_compliance,
              overall_progress: selected_compliance_trends
            }

            compliance.each do |pct, record|
              record.group_by(&:date).each do |date, object|
                threat_count_sum = if params[:adapter].blank?
                                     object.map(&:threat_count).min
                                   else
                                     object.map(&:threat_count).sum
                                   end
                total_threat_sum = if params[:adapter].blank?
                                     object.map(&:total_count).min
                                   else
                                     object.map(&:total_count).sum
                                   end
                value = ((threat_count_sum * 100) / total_threat_sum)
                if pct.to_s.eql?('cis_percentage')
                  cis_percentage << { value: value }
                elsif pct.to_s.eql?('pci_percentage')
                  pci_percentage << { value: value }
                elsif pct.to_s.eql?('nist_percentage')
                  nist_percentage << { value: value }
                elsif pct.to_s.eql?('hipaa_percentage')
                  hipaa_percentage << { value: value }
                elsif pct.to_s.eql?('awswa_percentage')
                  awswa_percentage << { value: value }
                elsif pct.to_s.eql?('overall_progress')
                  overall_percentage = (cis_percentage[-1][:value] + pci_percentage[-1][:value] + nist_percentage[-1][:value] + hipaa_percentage[-1][:value] + awswa_percentage[-1][:value]) / 5
                  overall_progress << { label: date.to_date, value: overall_percentage.ceil }
                end
              end
            end
          end
        end

      end

      favourite_dataset = [
        {
          'seriesname': 'CIS',
          'data': cis_percentage.flatten
        },
        {
          'seriesname': 'PCI',
          'data': pci_percentage.flatten
        },
        {
          'seriesname': 'NIST',
          'data': nist_percentage.flatten
        },
        {
          'seriesname': 'HIPAA',
          'data': hipaa_percentage.flatten
        },
        {
          'seriesname': 'AWSWA',
          'data': awswa_percentage.flatten
        }
      ]

      response = if response_flag
                   {
                     favourite: {
                       chart_data: {
                         categories:
                          [
                            category: categories.flatten
                          ],
                         dataset: favourite_dataset
                       }
                     },
                     overall: {
                       chart_data: overall_progress
                     }
                   }
                 else
                   {}
                 end
      status Status, :success, response, &block
    rescue StandardError => e
      CSLogger.error "Error in compliance states = #{e.message}"
      CSLogger.error e.backtrace
      status Status, :error, e.message, &block
    end

    def store_compliance_chart_data
      compliance_report_stats = []
      normal_active_adapters = Adapter.aws_normal_active_adapters
      normal_active_adapters.each do |adapter|
        CS_rule_ids_exist = SecurityScanStorage.where(adapter_id: adapter.id).distinct(:CS_rule_id)
        ComplianceStandard.where(standard_type: %w[CIS PCI NIST HIPAA AWSWA]).includes(:compliance_checks).each do |compliance_standard|
          compliance_rules = compliance_standard.compliance_checks
          automated_compliance_rules = compliance_rules.where(check_automated: true)
          threat_count = automated_compliance_rules.select { |rules| (rules.check_CS_ids & CS_rule_ids_exist).empty? }.count
          total_count = automated_compliance_rules.count
          next if total_count.zero?

          compliance_progress = (threat_count * 100) / total_count
          compliance_report_stats << {
            account_id: adapter.account_id,
            adapter_id: adapter.id,
            adapter_type: adapter.adapter_purpose,
            adapter_name: adapter.name,
            standard_type: compliance_standard.standard_type,
            standard_version: compliance_standard.standard_version,
            threat_count: threat_count,
            total_count: total_count,
            compliance_progress: compliance_progress,
            date: Date.today
          }
        end
      end
      ComplianceTrend.collection.insert_many(compliance_report_stats) if compliance_report_stats.any?
    end

    def calculate_compliance(CS_rule_ids)
      compliance_report_stats = []
      compliance_standards = ComplianceStandard.where(standard_type: %w[CIS PCI NIST HIPAA AWSWA]).includes(:compliance_checks)
      compliance_standards.each do |compliance_standard|
        compliance_rules = compliance_standard.compliance_checks
        automated_compliance_rules = compliance_rules.where(check_automated: true)
        threat_count = if CS_rule_ids.present?
                         automated_compliance_rules.select { |rules| (rules.check_CS_ids & CS_rule_ids).empty? }.count
                       else
                         0
                       end
        total_count = automated_compliance_rules.count
        compliance_progress = (threat_count * 100) / total_count
        compliance_report_stats << {
          standard_type: compliance_standard.standard_type,
          standard_version: compliance_standard.standard_version,
          threat_count: threat_count,
          total_count: total_count,
          compliance_progress: compliance_progress
        }
      end
      compliance_report_stats
    end

    def compliance_report_stats(current_tenant, params, &block)
      response = []
      if params[:adapter].blank? && params[:adapter_group_id].blank?
        compliance_report_stats = []
        current_tenant.adapters.aws_normal_active_adapters.each do |adapter|
          CS_rule_ids_exist = SecurityScanStorage.where(adapter_id: adapter.id).distinct(:CS_rule_id)
          compliance_report_stats << calculate_compliance(CS_rule_ids_exist)
        end
        compliance_report_stats.flatten.group_by { |x| x[:standard_type] }.each do |standard_type, compliance_report_stat|
          threat_count = compliance_report_stat.pluck(:threat_count).min
          total_count = compliance_report_stat.pluck(:total_count)[0]
          compliance_progress = (threat_count * 100) / total_count
          response << {
            standard_type: standard_type,
            threat_count: threat_count,
            total_count: total_count,
            compliance_progress: compliance_progress.ceil
          }
        end
      else
        adapter_ids = adapter_ids_from_filters(params, current_tenant)
        CS_rule_ids_exist = SecurityScanStorage.where(adapter_id: {'$in': adapter_ids}).distinct(:CS_rule_id)
        response = calculate_compliance(CS_rule_ids_exist)
      end
      status Status, :success, response, &block
    rescue StandardError => e
      CSLogger.error "Error in compliance states = #{e.message}"
      CSLogger.error e.backtrace
      status Status, :error, e.message, &block
    end

    def get_compliance_report_overview(current_account, current_tenant,params, &block)
      begin
        compliance_rules_details = get_compliance_rules_details(current_account, current_tenant,params)
        failed_compliance_rules = compliance_rules_details.each_with_object([]) {|(key, value), memo| memo.concat(value.select {|rule| !rule[:is_pass]})}
        compliance_report_summary = {
          fail_count_by_type: failed_compliance_rules.count,
          fail_count_by_resource: failed_compliance_rules.inject(0){|sum, rule| sum += rule[:fail_count]},
          chart_data: get_chart_data(failed_compliance_rules)
        }
        status Status, :success,compliance_report_summary, &block
      rescue Exception => e
        CSLogger.error "Error in compliance report overiew = #{e.message}"
        CSLogger.error e.backtrace
        status Status, :error, e.message, &block
      end
    end

    def get_csv_compliance_report(current_account, current_tenant, params)
      compliance_rules_details = compliance_rules_details_for_csv(current_account, current_tenant, params)
      
      tenant_adapter_ids = current_tenant.adapters.normal_adapters.aws_adapter.available.ids
      # filter_adapters = params[:adapter].present? ? [params[:adapter]] : tenant_adapter_ids
      filter_adapters = adapter_ids_from_filters(params, current_tenant)

      normal_adapters = Adapter.normal_adapters.aws_adapter.available.group_by(&:id)
      regions = Region.aws.group_by(&:id)

      security_scan_storages = SecurityScanStorage.where(:adapter_id.in => filter_adapters, :account_id => current_account.id)
      security_threats = []
      all_services = []
      security_scan_storages.group_by(&:CS_rule_id).each do |rule_id, security_scan|
        security_threats << {
          CS_rule_id: security_scan.pluck(:CS_rule_id).uniq[0],
          threat_description: security_scan.pluck(:scan_details).uniq[0],
          scan_details_desc: security_scan.pluck(:scan_details_desc).uniq[0],
          service_type: SERVICE_TYPES_MAP[security_scan.pluck(:service_type).uniq[0]],
          scan_status: security_scan.pluck(:scan_status).uniq[0],
          total_threat_count: security_scan.count
        }
        security_scan.each do |security_scan_object|
          all_services << {
            CS_rule_id: security_scan_object[:CS_rule_id],
            service_type: SERVICE_TYPES_MAP[security_scan_object[:service_type]],
            service_name: security_scan_object[:service_name],
            provider_id: security_scan_object[:provider_id],
            state: security_scan_object[:state],
            adapter_name: normal_adapters[security_scan_object[:adapter_id]].present? ? normal_adapters[security_scan_object[:adapter_id]].first.name : '',
            region_name: regions[security_scan_object[:region_id]].present? ? regions[security_scan_object[:region_id]].first.region_name: ''
          }
        end
      end

      compliance_check_attributes = {check_id:  "CheckID", recommendation: "Recommendation", is_pass: "Passed",severity: "Severity",automated: "Automated", fail_count: "Fail Count", description: "Description" }
      csv = CSV.generate(headers: true) do |csv|
        csv << compliance_check_attributes.values
        compliance_rules_details.each do |key, value|
          value.each do |compliance_check|
            csv << compliance_check_attributes.keys.map{|compliance_check_key| compliance_check[compliance_check_key]}
            filtered_security_threats = security_threats.select{|security_threat| compliance_check[:CS_rule_id].include?security_threat[:CS_rule_id]}
            unless filtered_security_threats.blank?
              security_threat_attributes = { blank: "", CS_rule_id: "CloudStreet Id", threat_description: "Threat Details", total_threat_count: "Threat Count", service_type: "Service Type", scan_status: "Scan status", scan_details_desc: "Threat Description"}
              csv << security_threat_attributes.values
              filtered_security_threats.each_with_index do |security_threat, index|
                csv << security_threat_attributes.keys.map{|security_threat_key| (security_threat_key == :blank) ? index+1 : security_threat[security_threat_key]}
                failed_services = all_services.select{|service| service[:CS_rule_id] == security_threat[:CS_rule_id]}
                unless failed_services.blank?
                  service_header = {blank: '', service_name: "Service Name", provider_id: "Provider ID", service_type: "Service Type", adapter_name: "Adapter", region_name: "Region", state: "State"}
                  csv << service_header.values
                  failed_services.each do |failed_service|
                    csv << service_header.keys.map{|service_header_key| failed_service[service_header_key]}
                  end
                end
              end
            end
            csv << []
          end
        end
      end
      csv
    end

    def compliance_rules_details_for_csv(current_account, current_tenant, params)
      tenant_adapter_ids = current_tenant.adapters.normal_adapters.aws_adapter.available.pluck(:id)
      compliance_standard = ComplianceStandard.find_by(standard_type: params[:standard_type], standard_version: params[:standard_version])
       if params[:standard_type] == 'CIS'
        compliance_rules = compliance_standard.compliance_checks.order('check_id::integer, check_section::integer, check_sub_section')
      else
        compliance_rules = compliance_standard.compliance_checks.order('check_id, check_section, check_sub_section')
      end
      compliance_rules = compliance_rules.where(check_id: params[:rule_type].to_s) if params[:rule_type].present?
      grouped_compliance_rules = compliance_rules.group_by(&:check_id)
      compliance_rules_details = {}
      CS_rule_ids = get_CS_rule_ids
      # filter_adapters = params[:adapter].present? ? [params[:adapter]] : tenant_adapter_ids
      filter_adapters = adapter_ids_from_filters(params, current_tenant)
      security_scans = SecurityScanStorage.where(:adapter_id.in => filter_adapters).group_by {|d| d.CS_rule_id}
      grouped_compliance_rules.each do |key, value|
        rules_list = []
        value.each do |rule|
          security_scan_storages = rule.check_CS_ids.each_with_object([]) {|check_CS_id, memo| memo.concat(security_scans[check_CS_id]) if security_scans[check_CS_id].present?}
          check_id = "#{rule.check_id}.#{rule.check_section}.#{rule.check_sub_section}"
          check_id[-1] = '' if (check_id[-1] == ".")
          rule_details = {
            id: rule.id,
            check_id: check_id,
            recommendation: rule.check_rule,
            description: rule.description,
            automated: rule.check_automated,
            CS_rule_id: security_scan_storages.pluck(:CS_rule_id)
          }
          if security_scan_storages.present?
            rule_details[:severity] = find_severity(security_scan_storages)
            rule_details[:is_pass] = false
            rule_details[:fail_count] = security_scan_storages.pluck(:adapter_id, :provider_id).count
          else
            rule_details[:is_pass] = true
            rule_details[:fail_count] = 0
          end
          rule_details[:implementation_status] = check_implemented_or_not(rule, CS_rule_ids) if rule.check_automated.eql?(true)
          rules_list.push(rule_details)
        end
        compliance_rules_details[key] = rules_list
      end
      compliance_rules_details
    end


    def get_compliance_report(current_account, current_tenant, params, &block)
      begin
        compliance_rules_details = get_compliance_rules_details(current_account, current_tenant, params)
        status Status, :success, compliance_rules_details, &block
      rescue StandardError => e
        CSLogger.error "Error in compliance report = #{e.message}"
        CSLogger.error e.backtrace
        status Status, :error, e.message, &block
      end
    end

    def get_compliance_rules_details(current_account, current_tenant, params)
      tenant_adapter_ids = current_tenant.adapters.normal_adapters.aws_adapter.available.pluck(:id)
      compliance_standard = ComplianceStandard.includes(:compliance_checks).find_by(standard_type: params[:standard_type], standard_version: params[:standard_version])
      compliance_rules = compliance_standard.compliance_checks
      compliance_rules = compliance_rules.where(check_id: params[:rule_type].to_s) if params[:rule_type].present?
      grouped_compliance_rules = compliance_rules.group_by(&:check_id)
      compliance_rules_details = {}
      CS_rule_ids = get_CS_rule_ids
      # filter_adapters = params[:adapter].present? ? [params[:adapter]] : tenant_adapter_ids
      filter_adapters = adapter_ids_from_filters(params, current_tenant)
      security_scans = SecurityScanStorage.where(:adapter_id.in => filter_adapters).group_by {|d| d.CS_rule_id}
      grouped_compliance_rules.each do |key, value|
        rules_list = []
        value.each do |rule|
          security_scan_storages = rule.check_CS_ids.each_with_object([]) {|check_CS_id, memo| memo.concat(security_scans[check_CS_id]) if security_scans[check_CS_id].present?}
          rule_details = {
            id: rule.id,
            check_id: rule.check_id,
            check_section: rule.check_section,
            check_sub_section: rule.check_sub_section,
            check_rule: rule.check_rule,
            description: rule.description,
            automated: rule.check_automated
          }
          if security_scan_storages.present?
            rule_details[:severity] = find_severity(security_scan_storages)
            rule_details[:is_pass] = false
            rule_details[:fail_count] = security_scan_storages.uniq.pluck(:adapter_id, :provider_id).count
          else
            rule_details[:is_pass] = true
            rule_details[:fail_count] = 0
          end
          rule_details[:implementation_status] = check_implemented_or_not(rule, CS_rule_ids) if rule.check_automated.eql?(true)
          rules_list.push(rule_details)
        end
        compliance_rules_details[key] = rules_list
      end
      compliance_rules_details
    end

    def find_severity(security_scan_storages)
      severities = {"low": 1, "medium": 2, "high": 3, "very high": 4}
      scan_status = security_scan_storages.pluck(:scan_status).uniq.compact
      max_severity = scan_status.collect {|status| severities[status.to_sym]}.max
      return severities.key(max_severity).to_s
    end

    def get_chart_data(failed_compliance_rules)
      severities_list = failed_compliance_rules.inject([]) {|memo, ele| memo << ele[:severity]}
      severity_count = {'very high': 0, 'high': 0, 'medium': 0, 'low': 0}
      severities_list.each { |severity| severity_count[severity.to_sym] += 1 }
      chart_data = severity_count.map {|k,v| {label: k.to_s, value: v}}
    end

    def get_CS_rule_ids
      begin
        file = File.read('data/rulesets/CS_rules.json')
        CS_rules = JSON.parse(file)
        CS_rule_ids = CS_rules.each_with_object([]) {|(service_type, rules), memo| memo.concat(rules.map {|d| d["CS_rule_id"] }) }.uniq
        CS_rule_ids.reject! {|CS_rule_id| CS_rule_id.blank?}
      rescue Exception => e
        CSLogger.error "Error during file read of security rules. message - #{e.message}"
        []
      end
    end

    def check_implemented_or_not(rule, CS_rule_ids)
      return '<span class="not-implemented">.</span>' if rule.check_CS_ids.blank?
      result = rule.check_CS_ids.collect {|check_CS_id| CS_rule_ids.include?(check_CS_id)}
      check_status = ''
      if result.include?(false)
        result.each {|e| check_status += (e ? '<span class="implemented">.</span>' : '<span class="not-implemented">.</span>')}
      end
      check_status
    end

    def find_security_threats(current_account,current_tenant, params, &block)
      begin
        tenant_adapter_ids = current_tenant.adapters.normal_adapters.aws_adapter.available.ids
        compliance_check = ComplianceCheck.find(params[:id])
        # filter_adapters = params[:adapter].present? ? [params[:adapter]] : tenant_adapter_ids
        filter_adapters = adapter_ids_from_filters(params, current_tenant)
        security_scan_storages = SecurityScanStorage.where(:adapter_id.in => filter_adapters, :CS_rule_id.in => compliance_check.check_CS_ids).group_by(&:CS_rule_id)
        security_threats = []
          security_threats = security_scan_storages.map do |rule_id, security_scan|
            {
              CS_rule_id: security_scan.pluck(:CS_rule_id).uniq[0],
              threat_description: security_scan.pluck(:scan_details).uniq[0],
              scan_details_desc: security_scan.pluck(:scan_details_desc).uniq[0],
              service_type: SERVICE_TYPES_MAP[security_scan.pluck(:service_type).uniq[0]],
              scan_status: security_scan.pluck(:scan_status).uniq[0],
              rule_type: security_scan.pluck(:rule_type).uniq[0],
              total_threat_count: security_scan.count
            }
          end
        status Status, :success, security_threats, &block
      rescue StandardError => e
        status Status, :error, e.message, &block
      end
    end

    def fetch_failed_services(current_account, current_tenant, params, &block)
      begin
        tenant_adapter_ids = current_tenant.adapters.normal_adapters.aws_adapter.available.ids
        # filter_adapters = params[:adapter].present? ? [params[:adapter]] : tenant_adapter_ids
        filter_adapters = adapter_ids_from_filters(params, current_tenant)
        security_threat_lists = SecurityScanStorage.where(:adapter_id.in => filter_adapters, :CS_rule_id => params[:CS_rule_id])
        adapters = Adapter.normal_adapters.aws_adapter.available.group_by(&:id)
        regions = Region.aws.group_by(&:id)
        failed_services = []
        unless adapters.blank? || regions.blank?
          failed_services = security_threat_lists.map {|security_threat| 
            {
              service_type: SERVICE_TYPES_MAP[security_threat.service_type],
              service_name: security_threat.service_name,
              provider_id: security_threat.provider_id,
              state: security_threat.state,
              adapter_name: adapters[security_threat.adapter_id].present? ? adapters[security_threat.adapter_id].first.name : '',
              region_name: regions[security_threat.region_id].present? ? regions[security_threat.region_id].first.region_name: ''
            }
          }
        end
        status Status, :success, failed_services, &block
      rescue StandardError => e
        status Status, :error, e.message, &block
      end
    end

    # Return tenant_adapter_ids if no adapter or group filter is present
    # Return array of adapter_ids from adapter filter OR group filter OR combined filters
    def adapter_ids_from_filters(filters, tenant)
      adapter_ids_from_filter(tenant, 'aws', filters[:adapter], filters[:adapter_group_id])
    end
  end
end
