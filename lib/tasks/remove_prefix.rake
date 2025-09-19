namespace :remove_prefix do
  desc 'This Task is for removing prefix from azure adapter names'

  task update_azure: :environment do
    Organisation.active.each do |organisation|
      CSLogger.info "Running for organisation #{organisation.subdomain}"
      next unless organisation.account.present?

      azure_billing_adapters = organisation.account.adapters.billing_adapters.azure_adapter
      azure_billing_adapters.where("data -> 'azure_account_type' in (?)", ['ss', 'ea']).each do |billing_adapter|
        if billing_adapter.azure_account_type.eql?('ss') && billing_adapter.adapter_name_prefix.present?
          fetch_subscription(billing_adapter)
        elsif billing_adapter.azure_account_type.eql?('ea') && billing_adapter.ea_account_setup.downcase.eql?('yes')
          ea_account_details = eval(billing_adapter.ea_account_details) if billing_adapter.ea_account_details.present?
          if ea_account_details.present?
            ea_account_details.each do |ea_account_detail|
              ea_adapter = Adapters::Creators::Azure.set_adapter(ea_account_detail, billing_adapter)
              fetch_subscription(ea_adapter)
            end
          end
        end
      end
    end
  end

  desc 'Update account setup details'
  task add_account_setup_details: :environment do
    azure_billing_adapters = Adapters::Azure.billing_adapters.where("data -> 'azure_account_type' = ?", 'ss')
    azure_billing_adapters.each do |billing_adapter|
      begin
        automatic_account_setup = billing_adapter.adapter_name_prefix.present? ? true : false
        billing_adapter.account_setup = automatic_account_setup
        billing_adapter.save!
      rescue ActiveRecord::RecordInvalid => e
        CSLogger.error e.message
        CSLogger.error e.class
      end
    end
  end

  def fetch_subscription(adapter)
    all_subscription = Adapters::Azure.normal_adapters.by_account(adapter.account_id)
    response = adapter.azure_subscriptions.list
    response.in_hash.on_success do |subscriptions|
      grouped_subscriptions = subscriptions.group_by { |subscription| subscription['display_name'] }
      grouped_subscriptions.each do |_subscription_name, subscriptions|
        subscriptions.each_with_index do |subscription, index|
          adapter_postfix = subscriptions.count > 1 ? index + 1 : ''
          adapter_name = adapter_postfix.present? ? "#{subscription['display_name']}-#{adapter_postfix}" : "#{subscription['display_name']}"
          normal_adapter = all_subscription.by_subscription_id(subscription['subscription_id']).available.first
          next unless normal_adapter.present?

          update_adapter_name(normal_adapter, adapter_name)
        end
      end
    end
  end

  def update_adapter_name(normal_adapter, adapter_name)
    normal_adapter.name = adapter_name
    normal_adapter.save!
  rescue ActiveRecord::RecordInvalid => e
    CSLogger.error e.message
    CSLogger.error e.class
  rescue StandardError => e
    CSLogger.error e.message
    CSLogger.error e.class
  end
end
