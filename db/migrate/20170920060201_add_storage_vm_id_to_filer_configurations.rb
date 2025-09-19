class AddStorageVmIdToFilerConfigurations < ActiveRecord::Migration[5.1]
  def up
    add_column :filer_configurations, :storage_vm_id, :uuid, index: true
    Filer.find_in_batches{|batch|
      batch.each do |filer|
        storage_vm_id = filer.storage_vms.pluck(:id).first
        FilerConfiguration.where(filer_id: filer.id).update_all(storage_vm_id: storage_vm_id)
      end
    }
    filer_ids = Filer.pluck(:id)
    StorageVm.where.not(filer_id: filer_ids).destroy_all
    Aggregate.where.not(filer_id: filer_ids).destroy_all
    FilerVolume.where.not(filer_id: filer_ids).destroy_all
    FilerConfiguration.where.not(filer_id: filer_ids).destroy_all
    Filer.where.not(id: filer_ids).destroy_all
  end

  def down
    remove_column :filer_configurations, :storage_vm_id
  end
end
