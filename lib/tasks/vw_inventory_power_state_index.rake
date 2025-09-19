namespace :vw_inventory_power_state_index do
  desc "Add index to vm inventory table for each client db"
  task add_indexing: :environment do
   Organisation.all.each do |org|
    CurrentAccount.client_db = org.account
    VwInventoryPowerState.create_indexes
    CSLogger.info "Index added for organisation #{org.subdomain}"
   end
  end

  # rake vw_inventory_power_state_index:vm_ware
  desc 'rake task to update vw inventories powerState'
  task vm_ware: :environment do
    error_list = []
    Adapters::VmWare.find_each do |adapter|
      begin
        CurrentAccount.client_db = adapter.account
        next if CurrentAccount.client_db.eql?('default')
        inventory_power_states = []
        adapter.vw_vcenters.each do |vw_vcenter|
          vw_inventories_list = vw_vcenter.vw_inventories
          next unless vw_inventories_list.present?
          vw_inventories_list.where("vw_inventories.data->>'powerState'=? and resource_type =? and status =?", 'poweredOn', 'VirtualMachine', 'terminated').find_each do |vw_inventorie|
            vw_inventorie.data['powerState'] = 'poweredOff'
            vw_inventorie.save
            inventory_power_states << {
              power_state: 'poweredOff',
              inventory_type: 'VirtualMachine',
              inventory_id: vw_inventorie.id,
              vcenter_id: vw_vcenter.id,
              created_at: vw_inventorie.terminated_at
            }
          end
        end
        VwInventoryPowerState.collection.insert_many(inventory_power_states) if inventory_power_states.any?
      rescue StandardError => e
        CSLogger.error "******* ERROR :: adapter_id #{adapter.id} :: #{e.message} *********"
        error_list << { adapter_id: adapter.id, error_message: e.message }
        CSLogger.error "----- error_list #{error_list} ---------"
      end
    end
  end
end
