# this class is used for vm_ware budgets processing
class Budget
  module Process
    module VmWare

      DIMENSION = ['month'].freeze

      attr_accessor :budget, :adapter, :tenant, :organisation, :account, :start_date, :end_date, :expires_date, :dimensions, :mertrics, :budget_accounts, :budget_groups, :start_month, :service_type, :user_activity_details, :budget_changes, :previous_budget_account_changes, :previous_budget_group_changes

      def build_query_vm_ware(tenant_budget)
        # If we create budget with only groups and not vcenters then its cost will be calculate based on groups, then
        # If suppose we delete all groups of that budget then budget vcenters and groups will be N/A. So, below we are making cost as 0.0 for this budget.
        if (budget_accounts.blank? && !budget.is_accounts_select_all? && budget_groups.blank?)
          mark_budget_as_empty(tenant_budget)
          tenant_budget.update(status: "success")
          return
        end

        vm_ware_budgets_data = []
        table_name = adapter.athena_cost_report_table
        CurrentAccount.client_db = Adapter.find_by(id: adapter.id).try(:account)
        currency = VmWareRateCard.where(account_id: account.id, adapter_id: adapter.id).first.try(:currency_unit) || 'USD'
        conditions = in_query('adapters.id', [adapter.id])

        if tenant_budget.is_shared
          vcenters = fetch_vcenter_ids_for_shared_budget(tenant_budget, budget)
          if vcenters.blank?
            mark_budget_as_empty(tenant_budget)
            tenant_budget.update(status: "success")
            return
         end

        else
         vcenters = if budget.is_accounts_select_all?
                      []
                    elsif budget_accounts.present? ||  budget_groups.present?
                      fetch_account_and_groups_vcenters
                    elsif organisation.present? && organisation.child_organisation? && tenant.organisation.account.vm_ware_billing_adapters(adapter.id)
                      []
                    elsif organisation.present? && !organisation.child_organisation? && tenant.vm_ware_has_billing(adapter.id)
                      []
                    else
                      VwVcenter.joins(:adapter).where(conditions).pluck('vw_vcenters.id')
                    end
        end

        vcenter_ids_query = "AND vcenter_id IN ('#{vcenters.join("','")}')" if vcenters.present?
        service_type_query = "AND resource_type IN ('#{service_type.join("','")}')" if service_type.present?
        tenant = tenant_budget.tenant
        projected_cost_column = vm_ware_projected_column(tenant)
        build_query_of_strings = "SELECT CONCAT(CAST(YEAR(CAST(created_at AS DATE)) AS VARCHAR(4)), '-', LPAD(CAST(MONTH(CAST(created_at AS DATE)) AS VARCHAR(02)), 2 , '0')) AS month, SUM(#{projected_cost_column}) AS cost FROM #{table_name} WHERE CAST(created_at AS DATE) >= CAST('#{start_date}' AS DATE) AND CAST(created_at AS DATE) <= CAST('#{end_date}' AS DATE) #{vcenter_ids_query} #{service_type_query} GROUP BY YEAR(CAST(created_at AS DATE)), MONTH(CAST(created_at AS DATE))  ORDER BY month ASC"
        CSLogger.info "the budgets data #{build_query_of_strings}"
        Athena::QueryService.exec(build_query_of_strings) do |query_status, query_resp|
          if query_status
            query_resp = budget_parse_athena_response(query_resp)
            vm_ware_budgets_data << query_resp
          else
            vm_ware_budgets_data << {}
          end
        end
        if (budget.start_month + 11.month).end_of_month < Date.today
          previous_month = 0.0
        else
          previous_month = vm_ware_budgets_data.first.select { |x| x.include?(Date.today.prev_month.strftime('%b %Y')) }.values.first.to_f
          vm_ware_budgets_data.select { |x| x.delete(Date.today.prev_month.strftime('%b %Y')) } if start_month.to_date.eql?(Date.today.beginning_of_month)
        end
        if budget.try(:expires_date).present? && budget.try(:expires_date).to_date < Date.today.beginning_of_month || (budget.start_month + 11.month).end_of_month < Date.today
          forecast = 0.0
        else
          date_range = { start_date: Date.today - 30, end_date: Date.yesterday }
          forecast_start_date = date_range[:start_date].to_date
          forecast_end_date = date_range[:end_date].to_date
          forecast_amount = []
          forecast = 0.0
 
          if start_month == Date.today.strftime('%B %Y') || start_month.to_date <= Date.today
            build_query_of_strings = "SELECT CONCAT(CAST(YEAR(CAST(created_at AS DATE)) AS VARCHAR(4)), '-', LPAD(CAST(MONTH(CAST(created_at AS DATE)) AS VARCHAR(02)), 2 , '0')) AS month, SUM(#{projected_cost_column}) AS cost FROM #{table_name} WHERE CAST(created_at AS DATE) >= CAST('#{forecast_start_date}' AS DATE) AND CAST(created_at AS DATE) <= CAST('#{forecast_end_date}' AS DATE) #{vcenter_ids_query} #{service_type_query} GROUP BY YEAR(CAST(created_at AS DATE)), MONTH(CAST(created_at AS DATE))  ORDER BY month ASC"
            Athena::QueryService.exec(build_query_of_strings) do |query_status, query_resp|
              if query_status
                query_resp = budget_parse_athena_response(query_resp)
                forecast_amount << query_resp
              end
            end
            forecast_amount = forecast_amount.present? ? forecast_amount.first.values.sum.round(2) : 0.0
            day_wise_forecast = (forecast_amount / 30)
            if start_month.to_date <= Date.today
              days = (Date.today.to_date.end_of_month.day - Date.today.day) + 1
              forecast = days * day_wise_forecast.round(2)
              day_wise_historic = 0.0
              build_query_of_strings = "SELECT  CAST(created_at AS DATE) AS date, SUM(#{projected_cost_column}) AS cost FROM #{table_name} WHERE CAST(created_at AS DATE) >= CAST('#{Date.today.to_s}' AS DATE) AND CAST(created_at AS DATE) <= CAST('#{Date.today.to_s}' AS DATE) #{vcenter_ids_query} #{service_type_query} GROUP BY CAST(created_at AS DATE)  ORDER BY CAST(created_at AS DATE) ASC"
              Athena::QueryService.exec(build_query_of_strings) do |query_status, query_resp|
                if query_status
                  query_resp = budget_parse_athena_response(query_resp)
                  day_wise_historic = query_resp.first.last.to_f if query_resp.first.present?
                end
              end
              forecast = forecast - day_wise_historic
            end
          end
        end
        # This method is used for new Budgets
        monthly_wise_budget_mails(vm_ware_budgets_data, currency, previous_month, forecast, tenant_budget)
        previous_status = tenant_budget.status
        tenant_budget.update(status: "success")
        current_status = tenant_budget.status
        #Commenting for now used to send notification when processed budget data 
        #send_notification_on_budget_share if previous_status == 'in_queue' && current_status == 'success'
      rescue StandardError => e
        CSLogger.error "Error calsulating budget: #{e.message}"
        CSLogger.error e.backtrace
        tenant_budget.update(status: "error")
      end

      def monthly_wise_budget_mails(vm_ware_budgets_data, currency, previous_month, forecast, tenant_budget)
        monthly_cost_to_date = vm_ware_budgets_data
        (budget.monthly_wise_budget || []).each do |date|
          unless monthly_cost_to_date.present? && monthly_cost_to_date.first.key?(date['month'])
            monthly_cost_to_date.first[date['month']] = 0
            monthly_cost_to_date
          end
        end
        vm_ware_budgets_cost = []
        monthly_threshold_emails = tenant_budget.monthly_threshold_email_flag || []
        threshold_values = []
        vm_ware_budgets_cost << monthly_cost_to_date.first.sort_by { |k, _| Date.strptime(k, '%b %Y') }.to_h
        tenant_budget.assign_attributes(monthly_cost_to_date: vm_ware_budgets_cost)
        monthly_emails = tenant_budget.monthly_email_flag || []
        (budget.monthly_wise_budget || []).each do |month|
          next unless monthly_cost_to_date.first.keys.include?(month['month']) && month['month'].to_date >= Date.today.beginning_of_month

          cost = monthly_cost_to_date.first[month['month']]
          cost = cost.present? ? cost : 0
          month_max_amount = month['max_amount']
          if cost.zero?
            tenant_budget.assign_attributes(state: 'limit_normal', over_budget: false, threshold_budget: false) if month['month'].eql?(Date.today.strftime('%b %Y'))
            next
          end
          budget_warning = month_max_amount * 0.90
          state = if cost > month_max_amount
            'vmware_limit_crossed'
          elsif cost.between?(budget_warning, month_max_amount)
            'vmware_limit_warning'
          else
            'limit_normal'
          end
          sent_email = state.eql?('vmware_limit_crossed')
          tenant_budget.assign_attributes(state: state, over_budget: sent_email)
          unless monthly_emails.include?(month['month'])
            trigger_budget_limit_api(currency, month_max_amount, cost, state, tenant_budget)
            if budget.notify || budget.custom_emails.present? || budget.notify_to.present?
              monthly_emails << month['month'] if sent_email
            end
          end
          (budget.threshold_value || []).each do |threshold|
            month_threshold_limit = (month_max_amount * threshold.to_f) / 100
            threshold_state = 'vmware_threshold_limit' if cost.between?(month_threshold_limit, month_max_amount)
            next unless threshold.to_f > 0.0 && threshold_state.present?

            sent_email = threshold_state.eql?('vmware_threshold_limit')
            tenant_budget.assign_attributes(state: threshold_state, threshold_budget: true) if sent_email
            threshold_alerts = if monthly_threshold_emails.first.present?
              monthly_threshold_emails.first.key?(month['month']) && monthly_threshold_emails.first[month['month']].include?(threshold)
            else
              false
            end
            next if threshold_alerts
            trigger_budget_threshold_limit_api(threshold, currency, month_max_amount, cost, threshold_state, tenant_budget) unless threshold_alerts
            if budget.notify || budget.custom_emails.present? || budget.notify_to.present?
              threshold_values << { month['month'] => threshold } if sent_email
            end
          end
        end
        if threshold_values.present?
          monthly_threshold_emails << threshold_values.each_with_object({}) { |h, o| h.each { |k, v| (o[k] ||= []) << v } }
          monthly_emails = []
        end
        tenant_budget.assign_attributes(monthly_email_flag: monthly_emails, monthly_threshold_email_flag: monthly_threshold_emails, monthly_cost_to_date: vm_ware_budgets_cost, prev_month_cost: previous_month, forecast_cost: forecast)
        # set_month_percentage
        tenant_budget_changes = tenant_budget.changes.present? ? tenant_budget.changes : {} if user_activity_details.present?
        tenant_budget.save
        record_user_activity(tenant_budget_changes, tenant_budget) if user_activity_details.present?
      end

      def budget_parse_athena_response(query_resp)
        result = query_resp.map { |response| response.try(:data) }.compact.to_json
        result = JSON.parse(result)
        result = result.drop(1)
        months = []
        result.each do |res|
          months << res.pluck('var_char_value')
        end
        months.to_h.transform_keys { |x| Date.strptime(x, '%Y-%m').strftime('%b %Y') }.transform_values { |i| i.to_f.round(2) }
      end

      def in_query(column_name, value)
        "#{column_name} IN ('#{value.is_a?(Array) ? value.join(',') : value}')"
      end

      def trigger_budget_limit_api(currency, month_max_amount, cost, state, tenant_budget)
        is_limit = state.eql?('vmware_limit_warning') || state.eql?('vmware_limit_crossed')
        return unless is_limit

        email_notify = state.eql?('vmware_limit_crossed')
        options = {
          budget_name: budget.name,
          email_notify: email_notify,
          notify_to: budget.notify_to,
          email_type: 'account_budget',
          subject_type: 'vCenter',
          account_id: account.id,
          currency: currency,
          max_amount: month_max_amount,
          cost_to_date: cost,
          tenant_name: tenant_budget.tenant.try(:name)
        }
        options[:custom_emails] = get_creator_or_custom_emails(budget)
        params = { 'account' => account.id, 'code' => state, 'additional_data' => options }
        ReportService.notifier(params)
      end

      def trigger_budget_threshold_limit_api(threshold, currency, month_max_amount, cost, state, tenant_budget)
        is_limit = state.eql?('vmware_threshold_limit')
        threshold_limit = (month_max_amount * threshold.to_f) / 100
        return unless is_limit

        email_notify = state.eql?('vmware_threshold_limit')
        options = {
          budget_name: budget.name,
          email_notify: email_notify,
          notify_to: budget.notify_to,
          email_type: 'account_budget',
          account_id: account.id,
          currency: currency,
          max_amount: month_max_amount,
          cost_to_date: cost,
          threshold_value: threshold,
          threshold_limit: threshold_limit,
          tenant_name: tenant_budget.tenant.try(:name)
        }
        options[:custom_emails] = get_creator_or_custom_emails(budget)
        params = { 'account' => account.id, 'code' => state, 'additional_data' => options }
        ReportService.notifier(params)
      end

      def get_creator_or_custom_emails(budget)
        return [] unless budget.notify

        if budget.notify && !budget.custom_emails.present? && !budget.notify_to.present?
          [budget.data["creator_email"]]
        elsif budget.custom_emails.present?
          budget.custom_emails
        end
      end      

      def record_user_activity(tenant_budget_changes, tenant_budget)
        change_logs = budget_changes.merge!(tenant_budget_changes)
        previous_client = Thread.current[:client_db]
        if budget.present? && (change_logs.present? || previous_budget_account_changes.present? || previous_budget_group_changes.present?)
          activity = Budget::Process::UserActivity.init_activity_for_budget(budget, user_activity_details)
          activity.data.merge!(name: budget.name)
          activity.log_data = change_logs
          activity.log_data.merge!(budget_account_changes) if budget_account_changes.present? && !previous_budget_account_changes.present?
          activity.log_data.merge!(difference_of_updated_budget_account) if previous_budget_account_changes.present? && difference_of_updated_budget_account.present?
          activity.log_data.merge!(calculate_forecast_percentage(tenant_budget_changes)) if tenant_budget.saved_change_to_forecast_cost?
          activity.log_data.merge!(month_related_percentage_details(tenant_budget_changes)) if tenant_budget.saved_change_to_monthly_cost_to_date?
          activity.log_data.merge!(month_related_percentage_details(tenant_budget_changes)) if tenant_budget.saved_change_to_prev_month_cost?
          activity.log_data.merge!(budget_group_changes) if budget_group_changes.present? && !previous_budget_group_changes.present?
          activity.log_data.merge!(difference_of_updated_budget_group) if previous_budget_group_changes.present? && difference_of_updated_budget_group.present?
          activity.save
        end
        Thread.current[:client_db] = previous_client
      end

      def calculate_forecast_percentage(tenant_budget_changes)
        previous_forecast_percentage = ((tenant_budget_changes[:forecast_cost][0].to_f / previous_max_amount) * 100) if tenant_budget_changes[:forecast_cost][0].present?
        current_forecast_percentage = (tenant_budget_changes[:forecast_cost][1].to_f / current_max_amount) * 100
        forecast_percentage = (data('forecast_percentage', previous_forecast_percentage, current_forecast_percentage))
        previous_total_balance = (previous_max_amount - tenant_budget_changes[:forecast_cost][0].to_f) if tenant_budget_changes[:forecast_cost][0].present?
        current_total_balance = (current_max_amount - tenant_budget_changes[:forecast_cost][1].to_f)
        total_balance = (data('total_balance', previous_total_balance, current_total_balance))
        forecast_percentage.merge!(total_balance)
      end

      def current_max_amount
        if budget.monthly_wise_budget.select { |mon| mon["month"].include?(Date.today.strftime("%b %Y")) }.present?
          budget.monthly_wise_budget.select { |mon| mon["month"].include?(Date.today.strftime("%b %Y")) }.first['max_amount'].to_f.round(2)
        else
          0.0
        end
      end

      def previous_max_amount
        if budget.monthly_wise_budget.select { |mon| mon["month"].include?(Date.today.prev_month.strftime("%b %Y")) }.present?
          budget.monthly_wise_budget.select { |mon| mon["month"].include?(Date.today.prev_month.strftime("%b %Y")) }.first['maz_amount'].to_f.round(2)
        else
          0.0
        end
      end

      def month_related_percentage_details(tenant_budget_changes)
        monthly_cost = tenant_budget_changes[:monthly_cost_to_date]
        current_percentage = ((previous_month(monthly_cost).eql?(0.0) ? 0 : (previous_month(monthly_cost) / previous_max_amount) * 100)) if tenant_budget_changes[:monthly_cost_to_date][0].first.present?
        current_percentage_changes = (current_month(monthly_cost).eql?(0.0) ? 0 : (current_month(monthly_cost) / current_max_amount * 100))
        data('current_month_percentage', current_percentage, current_percentage_changes)
      end

      def previous_month(monthly_cost)
        monthly_cost[0].try(:first).blank? ? 0.0 : monthly_cost[0].first.include?(Date.today.strftime('%b %Y')) ? monthly_cost[0].first.select { |k, v| v if k.include?(Date.today.strftime('%b %Y')) }.values.first.to_f : 0.0
      end

      def current_month(monthly_cost)
        current_month = monthly_cost[1].try(:first).blank? ? 0.0 : monthly_cost[1].first.include?(Date.today.strftime('%b %Y')) ? monthly_cost[1].first.select { |k, v| v if k.include?(Date.today.strftime('%b %Y')) }.values.first.to_f : 0.0
      end

      def previous_month_percentage
        monthly_cost = tenant_budget_changes[:monthly_cost_to_date]
        previous_percentage = tenant_budget_changes[:prev_month_cost][0].to_f.eql?(0.0) ? 0 : (previous_month(monthly_cost) / tenant_budget_changes[:prev_month_cost][0] * 100) if tenant_budget_changes[:prev_month_cost][0].present?
        previous_percentage_changes = tenant_budget_changes[:prev_month_cost][1].to_f.eql?(0.0) ? 0 : (current_month(monthly_cost) / tenant_budget_changes[:prev_month_cost][1].to_f) * 100
        data('previous_month_percentage', previous_percentage, previous_percentage_changes)
      end

      def budget_accounts_name
        budget.budget_accounts.pluck(:provider_account_name)
      end

      def budget_account_changes
        budget_accounts_name.present? ? data('vcenters', previous_budget_account_changes, budget_accounts_name) : {}
      end

      def difference_of_updated_budget_account
        if (previous_budget_account_changes - budget_accounts_name | budget_accounts_name - previous_budget_account_changes).present?
          data('vcenters', previous_budget_account_changes, budget_accounts_name)
        else
          {}
        end
      end

      def data(key, previous_budget_account_or_group_changes, budget_account_or_group_name)
        { key => [previous_budget_account_or_group_changes, budget_account_or_group_name] }
      end

      def assign_budget_data(budget, budget_changes, set_user_activity_details, budget_accounts_details, budget_groups_details)
        @budget_changes = budget_changes
        @user_activity_details = set_user_activity_details
        @previous_budget_account_changes = budget_accounts_details
        @previous_budget_group_changes = budget_groups_details
        @budget = budget
        @tenant = Tenant.find_by(id: budget.try(:tenant_id))
        @organisation = Organisation.find_by(id: budget.try(:organisation_id))
        @account = organisation.account
        @budget_accounts = budget.budget_accounts.pluck(:provider_account_id)
        @budget_groups = budget.budget_groups.pluck(:group_id)
        @adapter = Adapter.find_by(id: budget.try(:adapter_id))
        @start_month = budget.start_month
        @start_date = start_month.to_date.eql?(Date.today.beginning_of_month) ? (start_month.to_date - 1.month).to_s : start_month.to_date.to_s
        @end_date = if @expires_date.present?
                      (!expires_date.to_date.eql?(Date.today.beginning_of_month) && expires_date.to_date < Date.today) ? @expires_date.end_of_month.to_s : Date.today.to_s
                     else
                      (start_month + 11.month).end_of_month > Date.today.beginning_of_month ? Date.today.to_s : (start_month.to_date + 11.month).end_of_month.to_s
                    end
        @service_type = budget.service_type
      end

      def mark_budget_as_empty(tenant_budget)
        tenant_budget.prev_month_cost = 0.0
        tenant_budget.forecast_cost = 0.0
        tenant_budget.monthly_cost_to_date = [{}]
        tenant_budget.state = nil
        tenant_budget.save
      end

      def fetch_account_and_groups_vcenters
        # here Adding both vcenter ID's from budget_accounts and budget_groups and returning uniq vcenter ID's
        (budget_accounts | ServiceGroup.vcenterids_from_service_group(budget_groups))
      end

      def budget_groups_name
        budget.budget_groups.select(:group_id, :group_name).as_json if budget.present?
      end

      def budget_group_changes
        budget_groups_name.present? ? data("adapter_group", previous_budget_group_changes, budget_groups_name) : {}
      end

      def difference_of_updated_budget_group
        if (previous_budget_group_changes - budget_groups_name | budget_groups_name - previous_budget_group_changes).present?
          data("adapter_group", previous_budget_group_changes, budget_groups_name)
        else
          {}
        end
      end

      def mark_budget_as_empty(tenant_budget)
        tenant_budget.prev_month_cost = 0.0
        tenant_budget.forecast_cost = 0.0
        tenant_budget.monthly_cost_to_date = [{}]
        tenant_budget.state = nil
        tenant_budget.save
      end

      def projected_cost_column(tenant)
        report_profile = tenant.report_profile
        metric = tenant.is_default? ? 'cost' : 'net_cost'
        if report_profile.present?
          report_profile.provider_config[:VMware][:selected_metric].presence || metric
        else
          metric
        end
      end

      # def send_notification_on_budget_share
      #   params = { 'account' => account.id, 'code' => 'budget_shared', 'additional_data' => { budget_name: budget.name } }
      #   ReportService.notifier(params)
      # end

      def fetch_vcenter_ids_for_shared_budget(tenant_budget, budget)
        #If the Budget is shared to subtenant, then we're fetching that subtenant Vcenters.
        tenant_vcenter_ids = VwVcenterService.tenant_level_vw_vcenter_through_billing(tenant_budget.tenant, budget.adapter_id)
        budget_vcenter_ids =  if budget.is_accounts_select_all?
                                tenant_vcenter_ids
                              elsif budget_accounts.present? && budget_groups.blank?
                                (tenant_vcenter_ids & budget_accounts)
                              elsif budget_groups.present? && budget_accounts.blank?
                                (tenant_vcenter_ids & ServiceGroup.vcenterids_from_service_group(budget_groups))
                              elsif budget_accounts.present? && budget_groups.present?
                                (tenant_vcenter_ids & (budget_accounts | ServiceGroup.vcenterids_from_service_group(budget_groups)))
                              end
      end

      def vm_ware_projected_column(tenant)
        report_profile = tenant.report_profile
        metric = tenant.is_default? ? 'cost' : 'net_cost'
        if report_profile.present?
          report_profile.provider_config[:VMware][:selected_metric].presence || metric
        else
          metric
        end
      end

    end
  end
end