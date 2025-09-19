# frozen_string_literal: false

class CSIntegration::ComplianceReport::AWS::Service < CloudStreetService
  class << self
    def security_trends(_current_account, current_tenant, params, &block)
      response_flag = false
      tenant_adapter_ids = if params[:adapter].present?
                             params[:adapter].split
                           elsif params[:adapter_group_id].present?
                             ServiceGroup.adapterids_from_adapter_group(params[:adapter_group_id])
                           else
                             current_tenant.adapters.aws_normal_active_adapters.pluck(:id)
                           end
      categories = []
      
      compliance_trends = ComplianceTrend.where(:adapter_id.in => tenant_adapter_ids)
      
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
                  overall_percentage = ((cis_percentage[-1].try(:[], :value) || 0) + (pci_percentage[-1].try(:[], :value) || 0) + (nist_percentage[-1].try(:[], :value) || 0) + (hipaa_percentage[-1].try(:[], :value) || 0) + (awswa_percentage[-1].try(:[], :value) || 0)) / 5
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
                  overall_percentage = ((cis_percentage[-1].try(:[], :value) || 0) + (pci_percentage[-1].try(:[], :value) || 0) + (nist_percentage[-1].try(:[], :value) || 0) + (hipaa_percentage[-1].try(:[], :value) || 0) + (awswa_percentage[-1].try(:[], :value) || 0)) / 5
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

    def compliance_report_stats(current_tenant, params, &block)
      response = []
      if params[:adapter].blank?
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
        tenant_adapter_ids = if params[:adapter].present?
                               params[:adapter]
                             elsif params[:adapter_group_id].present?
                               ServiceGroup.adapterids_from_adapter_group(params[:adapter_group_id])
                             end
        CS_rule_ids_exist = SecurityScanStorage.where(adapter_id: tenant_adapter_ids).distinct(:CS_rule_id)
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

    def get_compliance_rules_details(current_account, current_tenant, params)
      tenant_adapter_ids = current_tenant.adapters.normal_adapters.pluck(:id)
      compliance_standard = ComplianceStandard.find_by(standard_type: params[:standard_type], standard_version: params[:standard_version])
      compliance_rules = compliance_standard.compliance_checks
      compliance_rules = compliance_rules.where(check_id: params[:rule_type].to_s) if params[:rule_type].present?
      grouped_compliance_rules = compliance_rules.group_by(&:check_id)
      compliance_rules_details = {}
      CS_rule_ids = get_CS_rule_ids
      # filter_adapters = params[:adapter].present? ? [params[:adapter]] : tenant_adapter_ids
      filter_adapters = adapter_ids_from_filters(params, tenant_adapter_ids)
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

    private

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

    def adapter_ids_from_filters(filters, tenant_adapter_ids)
      return Array[*filters[:adapter]] if filters[:adapter].present?

      return (tenant_adapter_ids & ServiceGroup.adapterids_from_adapter_group(filters[:adapter_group_id])) if filters[:adapter_group_id].present?

      tenant_adapter_ids
    end
  end
end
