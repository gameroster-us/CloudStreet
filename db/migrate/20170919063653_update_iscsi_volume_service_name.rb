class UpdateIscsiVolumeServiceName < ActiveRecord::Migration[5.1]
  def up
  	ServiceNamingDefault.where(service_type: 'ISCSI Volume').update_all(service_type: 'iSCSI Volume')
    Service.directory.where(type: Services::Compute::Server::IscsiVolume::AWS.to_s).update_all(name: 'iSCSI Volume')
  end
end
