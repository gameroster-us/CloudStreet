# frozen_string_literal: true

# RiSp config worker
class UpdateRISpBillingConfigurationWorker

  include Sidekiq::Worker
  sidekiq_options queue: :api, backtrace: true
  attr_reader :adapter_group_id, :adapter_group, :ri_sp_billing_configurations, :action_performed, :provider_mapping, :options

  PROVIDER_ACCOUNT_MAP = {
    aws: { accounts: 'child_accounts', id_col: 'account_id', name_col: 'account_name', acc_id_col: 'aws_account_id' }
  }.with_indifferent_access
  DELETED_STATUS = 'deleted'

  def perform(adapter_group_id:, action_performed: :update, options: {})
    @adapter_group_id = adapter_group_id
    @adapter_group = ServiceGroup.find_by(id: adapter_group_id)
    @action_performed = action_performed
    @options = options
    return unless pre_checks_succeeded?

    update_risp_billing_configurations
  end

  private

  def pre_checks_succeeded?
    return false if adapter_group.blank? && action_performed == :update

    provider_type = options[:provider_type].presence || adapter_group.provider_type.downcase
    return false unless PROVIDER_ACCOUNT_MAP.keys.include?(provider_type)

    @provider_mapping = PROVIDER_ACCOUNT_MAP[provider_type]
    set_current_account
    @ri_sp_billing_configurations = fetch_billing_configurations({ 'child_accounts.adapter_group_id' => adapter_group_id })
    ri_sp_billing_configurations.present?
  end

  def set_current_account
    current_account = if adapter_group.present?
      adapter_group.account
    else
      Account.find_by(id: options[:current_account_id])
    end
    CurrentAccount.client_db = current_account
  end

  def fetch_billing_configurations(conditions = {})
    # TODO: read only configs that has an end date greater than or equal to current month
    RISpBillingConfiguration.active.where(conditions)
  end

  def update_risp_billing_configurations
    if action_performed == :update
      options.keys.length == 1 && options.keys.include?(:name_changed) ? handle_name_update : handle_update
    elsif action_performed == :delete
      handle_deletion
    end
  end

  def populate_account_details_from_adapters(adapter_group, mapped_adapters, result)
    case adapter_group.provider_type
    when 'AWS'
      provider_mapping = PROVIDER_ACCOUNT_MAP[adapter_group.provider_type.underscore]
      account_details = mapped_adapters
                        .select("name AS adapter_name, data -> '#{provider_mapping[:acc_id_col]}' AS acc_id ")
                        .reject { |mapping| mapping.acc_id.blank? }
      return if account_details.empty?

      account_details.each do |detail|
        data = {
          provider_mapping[:id_col] => detail.acc_id,
          provider_mapping[:name_col] => "#{detail.adapter_name}(#{detail.acc_id})",
          'adapter_group_id' => adapter_group.id
        }
        result.push(data)
      end
    end
  end

  def handle_deletion
    ri_sp_billing_configurations.each do |billing_config|
      ri_adapter_grp = billing_config.reserved_instance[:adapter_groups]
      sp_adapter_grp = billing_config.saving_plan[:adapter_groups]
      account_details = billing_config.send(provider_mapping[:accounts])
      ri_adp_grp = ri_adapter_grp.pluck(:id)
      sp_adp_grp = sp_adapter_grp.pluck(:id)
      ri_acc = billing_config.reserved_instance[:aws_account_ids].pluck(:account_id)
      sp_acc = billing_config.saving_plan[:aws_account_ids].pluck(:account_id)
      child_accounts = []
      if ri_adp_grp.include?(adapter_group_id) && sp_adp_grp.include?(adapter_group_id)
        account_details.reject! { |account| account['adapter_group_id'] == adapter_group_id }
      else
        account_details.each do |account|
          if account[:adapter_group_id] != adapter_group_id
            child_accounts.insert(-1, account)
          elsif (ri_adp_grp.include?(adapter_group_id) && sp_acc.include?(account[:account_id])) || (sp_adp_grp.include?(adapter_group_id) && ri_acc.include?(account[:account_id]))
            child_accounts.insert(-1, { account_id: account[:account_id], account_name: account[:account_name] })
          end
        end
        account_details = child_accounts
      end
      ri_adapter_grp.reject! { |item| item['id'] == adapter_group_id }
      sp_adapter_grp.reject! { |item| item['id'] == adapter_group_id }
      billing_config.reserved_instance[:adapter_groups] = ri_adapter_grp
      billing_config.saving_plan[:adapter_groups] = sp_adapter_grp
      billing_config.send("#{provider_mapping[:accounts]}=", account_details)
      save_config_with_version(billing_config)
    end
  end

  def get_new_and_current_accounts
    newly_added_accounts = []
    previous_adapter_ids = options[:adapter_ids_was]
    current_accounts = Adapter.where(id: adapter_group.normal_adapter_ids)
                              .select("id as adapter_id, name AS adapter_name, data -> '#{provider_mapping[:acc_id_col]}' AS acc_id ")
                              .reject { |mapping| mapping.acc_id.blank? }
                              .map do |detail|
      newly_added_accounts.push(detail.acc_id) unless previous_adapter_ids.include?(detail.adapter_id)
      {
        provider_mapping[:id_col] => detail.acc_id,
        provider_mapping[:name_col] => "#{detail.adapter_name}(#{detail.acc_id})",
        'adapter_group_id' => adapter_group.id
      }
    end
    [newly_added_accounts, current_accounts]
  end

  def handle_update
    _newly_added_accounts, current_accounts = get_new_and_current_accounts
    is_all_selected = adapter_group.normal_adapter_ids.blank? && !adapter_group.is_group_empty
    ri_sp_billing_configurations.each do |billing_config| 
      existing_accounts = billing_config.send(provider_mapping[:accounts])
      ri_adp_grp = billing_config.reserved_instance[:adapter_groups].pluck(:id)
      sp_adp_grp = billing_config.saving_plan[:adapter_groups].pluck(:id)
      ri_acc = billing_config.reserved_instance[:aws_account_ids].pluck(:account_id)
      sp_acc = billing_config.saving_plan[:aws_account_ids].pluck(:account_id)
      child_accounts = []
      if ri_adp_grp.include?(adapter_group.id) && sp_adp_grp.include?(adapter_group.id)
        existing_accounts.reject! { |account| account['adapter_group_id'] == adapter_group.id }
      else
        existing_accounts.each_with_index do |account, index|
          if account[:adapter_group_id] != adapter_group.id
            child_accounts.insert(-1, account)
          elsif current_accounts.pluck('account_id').include?(account[:account_id])
            next
          elsif (ri_adp_grp.include?(adapter_group.id) && sp_acc.include?(account[:account_id])) || (sp_adp_grp.include?(adapter_group.id) && ri_acc.include?(account[:account_id]))
            child_accounts.insert(-1, { account_id: account[:account_id], account_name: account[:account_name] })
          end
        end
        existing_accounts = child_accounts
      end
      final_accounts = (current_accounts + existing_accounts).uniq
      final_accounts.sort_by! { |account| account.with_indifferent_access[provider_mapping[:id_col]] }
      billing_config.send("#{provider_mapping[:accounts]}=", final_accounts)
      reassign_adapter_group_name(billing_config) if options[:name_changed]
      save_config_with_version(billing_config)
    end
  end

  def handle_name_update
    ri_sp_billing_configurations.each do |risp_billing_config|
      reassign_adapter_group_name(risp_billing_config)
      save_config_with_version(risp_billing_config)
    end
  end

  def reassign_adapter_group_name(risp_billing_config)
    ri_adapter_grp = risp_billing_config.reserved_instance['adapter_groups']
    sp_adapter_grp = risp_billing_config.saving_plan['adapter_groups']
    ri_adapter_grp.select { |item| item['id'] == adapter_group.id }.each { |item| item['name'] = adapter_group.name }
    sp_adapter_grp.select { |item| item['id'] == adapter_group.id }.each { |item| item['name'] = adapter_group.name }
    risp_billing_config.reserved_instance['adapter_groups'] = ri_adapter_grp
    risp_billing_config.saving_plan['adapter_groups'] = sp_adapter_grp
  end

  def save_config_with_version(risp_billing_config)
    accounts_field = provider_mapping[:accounts]
    valid_accounts = risp_billing_config.send(accounts_field).any? { |account| account['status'] != DELETED_STATUS } || risp_billing_config.reserved_instance[:adapter_groups].present? || risp_billing_config.saving_plan[:adapter_groups].present?
    if !valid_accounts && risp_billing_config.changed_attributes.keys.include?(accounts_field)
      if can_destroy?(risp_billing_config)
        risp_billing_config.destroy
        return
      else
        risp_billing_config.status = DELETED_STATUS
      end
    end
    risp_billing_config.save!
    version_attrs = risp_billing_config.attributes.except('_id', '_type', 'versions_count').tap do |version|
      version[:modifier_name] = risp_billing_config.modifier_name
    end
    risp_billing_config.versions.create!(version_attrs)
  end

  def can_destroy?(billing_config)
    current_month = Date.today.strftime('%Y-%m')
    config_created_month = billing_config.created_at.strftime('%Y-%m')
    start_month = Date.parse(billing_config.start_month).strftime('%Y-%m')
    config_created_month == current_month || current_month <= start_month
  end

end
