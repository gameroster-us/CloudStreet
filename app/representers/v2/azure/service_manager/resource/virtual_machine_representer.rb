module V2::Azure::ServiceManager::Resource::VirtualMachineRepresenter
  
  include Roar::JSON
  include Roar::Hypermedia
  include ServiceManager::Azure::ResourceRepresenter

  property :vm_size
  property :vm_status
  property :network_interfaces
  property :os_disk
  property :data_disks
  property :image_reference
  property :operating_system

  def operating_system
    self.os_disk['os_type']
  end

end

