module StorageVms
  module CloudResources
    class NetAppService < CloudStreetService

      def self.list(account, page_params, filer_params, &block)
        storage_vms = StorageVm.joins(:filer).where(filers: {account_id: account.id}).order(name: :desc)
        storage_vms = storage_vms.where("storage_vms.name LIKE ?", "%#{filer_params[:name]}%") if filer_params[:name].present?
        storage_vms = storage_vms.where("storage_vms.language LIKE ?", "%#{filer_params[:language]}%") if filer_params[:language].present?
        storage_vms = storage_vms.where("storage_vms.state LIKE ?", "%#{filer_params[:state]}%") if filer_params[:state].present?
        storage_vms = storage_vms.where(filer_id: filer_params[:filer_id]) if filer_params[:filer_id].present?

        storage_vms, total_records = apply_pagination(storage_vms, page_params)

        status Status, :success, [storage_vms, total_records], &block
      end

      def self.update(account, vm_params, &block)
        vm = StorageVm.where(id: vm_params[:id]).joins(:filer).where(filers: {account_id: account.id}).first
        if vm
          vm.cifs_nfs_mount_ip = IPAddr.new(vm_params[:cifs_nfs_mount_ip].gsub(/\s+/, "")).to_s
          vm.save!
        end
        status Status, :success, nil, &block
      rescue IPAddr::InvalidAddressError => exception
        status Status, :validation_error, [exception.message.camelize], &block
      end
    end
  end
end