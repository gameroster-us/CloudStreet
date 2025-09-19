# frozen_string_literal: true

namespace :vm_ware_cost_report do
  desc 'task to generate VMware cost reports'
  # Example usage:
  #   rake vm_ware_cost_report:generate => generates cost report data for vmware according to the VMWARE_DATA_REPROCESS_DAY value
  #   rake vm_ware_cost_report:generate[2021-11-12] => generates cost report for the mentioned date
  #   rake vm_ware_cost_report:generate[2021-11-12,adapter_id1,adapter_id2,..adapter_idn] =>
  #     generate cost reports for the mentioned adapter ids on the mentioned date.
  task :generate, [:target_date] => [:environment] do |_, args|
    start_generating(args, false)
  end

  task :target_date_regenerate, [:target_date] => [:environment] do |_, args|
    start_generating(args, true)
  end

  # Example usage:
  #   rake vm_ware_cost_report:regenerate => reprocess cost report for all accounts
  #   rake vm_ware_cost_report:regenerate[adapter_id1,adapter_id2,...,adapter_idn] => reprocess cost report for all selected adapters
  # task regenerate: [:environment] do |_, args|
  #   adapter_ids = args.extras
  #   abort('====================== ExecutionHalted: Invalid AdapterID=====================') if
  #     adapter_ids.present? && invalid_adapter_ids_passed?(adapter_ids)

  #   mapping = adapter_to_vcenter_mapping(adapter_ids,)
  #   if mapping.blank?
  #     CSLogger.error "======== No Adapters Found to reprocess"
  #     return
  #   end
  #   mapping.each do |adapter_id, vcenter_ids|
  #     dispatch_reprocess_jobs_in_batches(adapter_id, vcenter_ids)
  #   end
  #   if mapping.count.positive?
  #     CSLogger.info '====================== VMware Cost Report Jobs Dispatched ====================='
  #   else
  #     CSLogger.info '====================== No relevant data to process ====================='
  #   end
  # end

  def start_generating(args, is_regenerated)
    adapter_ids = args.extras
    abort('====================== ExecutionHalted: Invalid AdapterID=====================') if
      adapter_ids.present? && invalid_adapter_ids_passed?(adapter_ids)

    reprocess_date_count = CommonConstants::VMWARE_DATA_REPROCESS_DAY || 10
    start_date, end_date = if args[:target_date].present?
      [Date.parse(args[:target_date]), Date.parse(args[:target_date])]
    else
      [Date.today - reprocess_date_count.day, Date.yesterday]
    end

   # CSLogger.info "====================== VMware Cost Report for start_date:#{start_date} and end_date: #{end_date} ======================"
    mapping = adapter_to_vcenter_mapping(adapter_ids, start_date, end_date)
    if mapping.blank?
      CSLogger.error "======== No Adapters Found to reprocess"
      return
    end
    abort('====================== ExecutionHalted::NoMatchindVcenter =====================') if mapping.blank?

    mapping.each do |adapter_id, vcenter_ids|
      dispatch_jobs_in_batches(start_date, end_date, adapter_id, vcenter_ids, is_regenerated)
    end
    CSLogger.info '====================== VMware Cost Report Jobs Dispatched ====================='
  end

  def adapter_to_vcenter_mapping(adapter_ids = [], start_date, end_date)
    condition = adapter_ids.present? ? ['adapters.id IN (?)', adapter_ids] : ''
    Adapters::VmWare.where(condition)
                    .joins(:vw_vcenters)
                    .joins(:vw_vdc_files)
                    .where(vw_vdc_files: {created_at: (start_date.beginning_of_day..end_date.end_of_day)})
                    .select('adapters.id AS adapter_id', 'vw_vcenters.id AS vcenter_id')
                    .group_by(&:adapter_id)
                    .transform_values { |values| values.pluck(:vcenter_id).uniq }
  end

  def dispatch_jobs_in_batches(start_date, end_date, adapter_id, vcenter_ids, is_regenerated = false)
    adapter = Adapter.find(adapter_id)
    account = adapter.account
    return unless account.is_trial_period && account.organisation.is_active

    CurrentAccount.client_db = account
    rate_card = VmWareRateCard.where(account_id: account.id, adapter_id: adapter.id).last
    if rate_card.blank?
      CSLogger.info 'Skipping data reprocess due to rate card not present for given dates'
      return
    end
    rate_card_date = rate_card.created_at.to_date
    filtered_dates = (start_date..end_date).select { |date| date >= rate_card_date }

    options = { adapter_id: adapter_id, end_date: end_date, dispatch_time: Time.now, is_monthly: false, is_regenerated: is_regenerated, vcenter_id: vcenter_ids.first, start_date: start_date}
    batch = Sidekiq::Batch.new
    batch.on(:success, VmWare::InventoryCostUploaderWorker, options)
    batch.jobs do
      filtered_dates.uniq.each do |target_date|
        vcenter_ids.each do |vcenter_id|
          if is_regenerated
            VmWare::InventoryCostUploaderWorker.set(queue: 'vmware_metric_regenerate').perform_async(vcenter_id, target_date, true)
          else
            VmWare::InventoryCostUploaderWorker.perform_async(vcenter_id, target_date, false)
          end
        end
      end
    end
  end

  # This method currently not in use
  # def dispatch_reprocess_jobs_in_batches(adapter_id, vcenter_ids)
  #   adapter = Adapters::VmWare.find_by(id: adapter_id)
  #   account = adapter.account
  #   CurrentAccount.client_db = account
  #   today = Date.today
  #   dates_to_reprocess = VwInventoryPowerState.powered_on
  #                                             .where(:vcenter_id.in => vcenter_ids)
  #                                             .pluck(:created_at)
  #                                             .map(&:to_date)
  #                                             .uniq
  #   dates_to_reprocess -= [today]
  #   dates_grouped_by_month = dates_to_reprocess.group_by { |date| date.strftime('%Y-%m') }
  #   adapter_batch = Sidekiq::Batch.new
  #   options = { adapter_id: adapter_id, adapter_batch_bid: adapter_batch.bid }
  #   adapter_batch.on(:success, ::VmWare::TableUpdater, options)
  #   adapter_batch.jobs do
  #     dates_grouped_by_month.each do |month, dates|
  #       monthly_batch = Sidekiq::Batch.new
  #       options[:month] = month
  #       monthly_batch.on(:success, ::VmWare::GlueJobExecutor, options)
  #       monthly_batch.jobs do
  #         dates.each do |target_date|
  #           vcenter_ids.each { |vcenter_id| VmWare::InventoryCostReUploaderWorker.perform_async(vcenter_id, target_date) }
  #         end
  #       end
  #     end
  #   end
  # end

  def invalid_adapter_ids_passed?(adapter_ids)
    Adapters::VmWare.where(id: adapter_ids).count != adapter_ids.count
  end
end
