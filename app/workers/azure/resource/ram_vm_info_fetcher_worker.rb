# frozen_string_literal: false

# Worker to store RAM VM information to VM
class Azure::Resource::RamVmInfoFetcherWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'azure_sync', backtrace: true, retry: true

  def perform(adapter_id)
    adapter = Adapter.find_by(id: adapter_id)
    return unless adapter

    CSLogger.info "Started fetching Azure Ram INFO VM for adapter : #{adapter.name} ID : #{adapter.id}, please wait ..."

    Region.get_enabled_regions(adapter.account.id, :azure).pluck(:id, :code).each do |region_id, region_code|
      all_virtual_machine_sizes_info = adapter.azure_virtual_machines.list_virtual_machine_sizes(region_code)
      if all_virtual_machine_sizes_info.data.empty?
        CSLogger.error "Sorry!!! No VM Size found for Azure Ram INFO VM for adaper : #{adapter.name} ID : #{adapter.id} | #{region_code} | #{all_virtual_machine_sizes_info&.error_message}"
        next
      end
      all_vm_instances = []
      Azure::Resource::Compute::VirtualMachine.where(adapter_id: adapter.id, region_id: region_id).each do |vm_instance|
        vm_info = all_virtual_machine_sizes_info.data.find { |size| size['name'].eql?(vm_instance.vm_size) }
        if vm_info.present?
          vm_instance.ram_size = vm_info['memoryInMB'] * 1024 * 1024 || 0.0
          all_vm_instances << vm_instance
        end
      end
      Azure::Resource.import all_vm_instances, on_duplicate_key_update: { conflict_target: [:id], columns: [:data] } if all_vm_instances.any?
    end

    CSLogger.info "Completed fetching  Azure Ram INFO VM for adaper : #{adapter.name} ID : #{adapter.id}"
  rescue StandardError => e
    CSLogger.error "==== Error while fetching Azure Ram INFO VM  for adaper #{adapter.name} | ID : #{adapter.id} Error : #{e.message}===="
  end

end
