class AzureCspCustomerFetcherWorker
  include CspAdapterQueryHelper
  include Sidekiq::Worker
  sidekiq_options queue: :athena_group_sync, retry: false, backtrace: true

  def perform(adapter_id, customer_size = 10000)
    adapter = Adapter.find(adapter_id)
    type = adapter.type.split('::').last
    account_group_flag = false
    account = adapter.account
    parent_organisation = adapter.account.organisation
    tenant = adapter.account.organisation.get_default_tenant
    owner = adapter.account.organisation.owner

    CSLogger.info "#{self.class} : ======= STARTED : customer fetching for adapter - #{adapter.name} ======="
    customers = get_customers_list(adapter)
    CSLogger.info "#{self.class} : ======= DONE : customer fetching for adapter - #{adapter.name} ======="

    CSLogger.info  "#{self.class} : ======= STARTED : subscriptions fetching for  all customer of -> #{adapter.name} ======="
    customer_subscriptions = get_grouped_customer_subscriptions(adapter, customers.pluck('id'))
    CSLogger.info  "#{self.class} : ======= DONE : subscriptions fetching for  all customer of -> #{adapter.name} ======="

    customer_id_detail_map = customers.each_with_object({}){|customer, memo| memo[customer['id']] = customer}
    customer_subscriptions.each do |customer_id, subscriptions|
      customer = customer_id_detail_map[customer_id]
      begin
        if subscriptions.blank?
          CSLogger.info "Skipping Group creation subscriptions not present-------------"
          next
        end

        normal_adapters = Adapters::Azure.where(account_id: account.id).normal_adapters.where("data-> 'subscription_id' in(?)", subscriptions)
        if normal_adapters.blank?
          CSLogger.info "Skipping Group creation subscription normal adapter not present-------------"
          next
        end

        
        service_group = ServiceGroup.find_by(customer_id: customer['id'], account_id: adapter.account_id)
        if service_group.present?
          is_subscriptions_already_exists = ((subscriptions - service_group.customer_subscriptions) | (service_group.customer_subscriptions - subscriptions)).empty?
          next if is_subscriptions_already_exists && service_group.custom_data.present?

          CSLogger.info "#{self.class} : ======= UPDATING : group for customer -> #{customer['name']}, Adapter -> #{adapter.name} ======="
          adapter_group_params = service_group.attributes
          adapter_group_params['customer_subscriptions'] = subscriptions
          adapter_group_params['custom_data'] = service_group.custom_data.present? ? service_group.custom_data : {'Customer Domain Name': customer['domain'], 'Customer Id': customer['id']}
          Groups::Updater.call(account, service_group, adapter_group_params, tenant, owner, account_group_flag: false)
          account_group_flag = true
        else
          adapter_group_params = {
            'normal_adapter_ids'=> [],
            'billing_adapter_id'=> adapter.id,
            'description'=> "Adapter group for customer #{customer['name']}",
            'name'=> customer['name'],
            'provider_type'=> "Azure",
            'tags' => [],
            'type'=> "generic",
            'custom_data' => {'Customer Domain Name': customer['domain'], 'Customer Id': customer['id']},
            'customer_id' =>  customer['id'],
            'customer_name' => customer['name'],
            'customer_subscriptions' => subscriptions
          }

          CSLogger.info "#{self.class} : ======= CREATING : group for customer -> #{customer['name']}, Adapter -> #{adapter.name} ======="
          group_status, group_data = Groups::Creator.call(account, tenant, adapter_group_params, false)
          if group_status
            service_group = group_data
            account_group_flag = true
          else
            CSLogger.error "Failed to create adapter group for customer - #{customer['name']} of adapter - #{adapter.id} due to - #{group_data}"
            next
          end
        end
      rescue Exception => e
        CSLogger.error e.message
        CSLogger.error e.backtrace
        Honeybadger.notify(e) if ENV['HONEYBADGER_API_KEY']
        next
      end
    end
    AthenaTableSchemaUpdateWorker.perform_action(account.organisation_identifier, type) if account_group_flag
    CSLogger.info "#{self.class} : ======= COMPLETED : customer subscription fetching and group creation for - #{adapter.name} ======="
  rescue Exception => e
    CSLogger.error e.message
    CSLogger.error e.backtrace
    Honeybadger.notify(e) if ENV['HONEYBADGER_API_KEY']
  end

  private

  def get_customers_list(adapter)
    response = AzureCustomerFetcher.get_customers_list(adapter, false)
    response[:customers]
  end

  def get_customer_subscriptions(adapter, customer)
    table_name = adapter.account.organisation_identifier.try(:downcase) + adapter.get_table_postfix + '_az'
    query_string = "SELECT DISTINCT subscription_guid FROM #{table_name} where customer_tenant_id='#{customer['id']}' "
    Athena::QueryService.exec(query_string) do |status, query_resp|
      if status
        query_resp = Athena::QueryService.parse_athena_response(query_resp).pluck('subscription_guid')
      else
        CSLogger.error "Query Failed, Error: #{query_resp}"
        []
      end
    end
  end

  # this method return hash containing customer and subscription mapping
  def get_grouped_customer_subscriptions(adapter, customer_ids, slice_size = 500)
    customer_ids = [* customer_ids].compact
    query_response = []
    table_name = adapter.account.organisation_identifier.try(:downcase) + adapter.get_table_postfix + '_az'
    customer_ids.each_slice(slice_size) do |sliced_customer_ids|
      customer_ids_in = sliced_customer_ids.map { |customer_id| "'#{customer_id}'" }.join(',')
      query_string = "SELECT DISTINCT customer_tenant_id, subscription_guid FROM #{table_name} where customer_tenant_id IN(#{customer_ids_in}) #{additional_filters_for_csp_in_string(adapter)}"
      query_response.concat(fetch_athena_result(query_string))
    end

    query_response.each_with_object({}) do |result, memo|
      (memo[result['customer_tenant_id']] ||= []) << result['subscription_guid']
    end
  end

  def fetch_athena_result(query_string)
    Athena::QueryService.exec(query_string) do |status, query_resp|
      if status
        Athena::QueryService.parse_athena_response(query_resp)
      else
        CSLogger.error "Query Failed, Error: #{query_resp}"
        []
      end
    end
  end

end