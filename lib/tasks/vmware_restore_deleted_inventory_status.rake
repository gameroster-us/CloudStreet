# frozen_string_literal: true

namespace :vmware_restore_deleted_inventory_status do
  desc 'task to generate inventory power states for missing vdc timestamp'
  #   rake vmware_restore_deleted_inventory_status:restore => generate inventory power states for yesterday
  #   rake vmware_restore_deleted_inventory_status:restore[2021-11-22] => generate inventory power states for mentioned date
  task :restore, [:target_date] => [:environment] do |_task, args|
    adapter_ids = args.extras
    abort('====================== ExecutionHalted: Invalid AdapterID=====================') if
      adapter_ids.present? && invalid_adapter_ids_passed?(adapter_ids)

    target_date = begin
                    Date.parse(args[:target_date])
                  rescue StandardError
                    nil
                  end
    abort('====================== ExecutionHalted: Target date not Valid =====================') unless target_date.present?
    condition = adapter_ids.present? ? ['vw_vdc_files.adapter_id IN (?)', adapter_ids] : ''
    adapter_vdc_files_mapping = VwVdcFile.where(condition)
                                         .where(created_at: (target_date.beginning_of_day..target_date.end_of_day)).group_by(&:adapter_id)
    if adapter_vdc_files_mapping.present?
      adapter_vdc_files_mapping.each do |adapter_id, vdc_files|
        restore_inventories(adapter_id, vdc_files)
      end
    end
  end

  # rake "vmware_restore_deleted_inventory_status:monthly_restore[02-2023, adapter_id_1, adapter_id_2, adapter_id_3 ... adapter_id_n]"
  task :monthly_restore, [:target_month] => [:environment] do |_task, args|
    abort('====================== ExecutionHalted: target_months not present =====================') unless args[:target_month]
    adapter_ids = args.extras
    abort('====================== ExecutionHalted: Invalid AdapterID=====================') if
    adapter_ids.present? && invalid_adapter_ids_passed?(adapter_ids)  

    target_month = args[:target_month].split('-')
    CSLogger.info "Processing for target_date : #{args[:target_month]} started"
    target_date = Date.new(target_month[1].to_i,target_month[0].to_i)
    start_date = target_date.beginning_of_month.beginning_of_day
    end_date = target_date.end_of_month.end_of_day
    condition = adapter_ids.present? ? ['vw_vdc_files.adapter_id IN (?)', adapter_ids] : ''
    adapter_vdc_files_mapping = VwVdcFile.where(condition)
                                         .where(created_at: (start_date.beginning_of_day..end_date.end_of_day)).group_by(&:adapter_id)
    next unless adapter_vdc_files_mapping.present?
   
    adapter_vdc_files_mapping.each do |adapter_id, vdc_files|
      restore_inventories(adapter_id, vdc_files)
    end
  end

  def restore_inventories(adapter_id, vdc_files)
    CSLogger.info "Generation for Adapter_id : #{adapter_id} started"
    account = Adapter.find(adapter_id).account
    CurrentAccount.client_db = account

    vdc_files.each do |vdc_file|
      CSLogger.info "Power state generation for Vdc File : #{vdc_file.id} started"
      VmWare::InventoryRestoreService.new(vdc_file).process
    end

    CSLogger.info "Generation for Adapter_id: #{adapter_id} Done"
  end

  def invalid_adapter_ids_passed?(adapter_ids)
    Adapters::VmWare.where(id: adapter_ids).count != adapter_ids.count
  end
end
