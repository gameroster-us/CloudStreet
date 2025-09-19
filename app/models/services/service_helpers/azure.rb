module Services::ServiceHelpers::Azure
  private
  def connection_vn
    adapter.connection_vn
  end

  def connection_vm
    adapter.connection_vm
  end

  def connection_rds
    adapter.connection_rds
  end

  def parent_remote_vpc
    connection_vn.list_virtual_networks.find { |v| v.id == provider_vpc_id }
  end
end
