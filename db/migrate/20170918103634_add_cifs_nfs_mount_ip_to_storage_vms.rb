class AddCifsNfsMountIpToStorageVms < ActiveRecord::Migration[5.1]
  def change
    add_column :storage_vms, :cifs_nfs_mount_ip, :string
  end
end
