class ProviderWrappers::Azure::Databases::Postgresql::ServerProvider < ProviderWrappers::Azure

  def list(resource_group_name)
    res = client.servers.list_by_resource_group(resource_group_name)
    @response.set_response(:success, res.value)
  rescue MsRestAzure::AzureOperationError => e
    @response.set_response(:error, [], e.error_message, e.error_code)
  end

  def get(resource_group_name, server_name)
    res = client.servers.get(resource_group_name, server_name)
    @response.set_response(:success, res)
  rescue MsRestAzure::AzureOperationError => e
    @response.set_response(:error, [], e.error_message, e.error_code)
  end

  def delete(resource_group_name, server_name)
    res = client.servers.delete(resource_group_name, server_name)
    @response.set_response(:success, res)
  rescue MsRestAzure::AzureOperationError => e
    @response.set_response(:error, [], e.error_message, e.error_code)
  end

  def update_tags(resource_group_name, server_name, parameters)
    parameters = build_model(Azure::Postgresql::Profiles::Latest::Mgmt::Models::Server, parameters)
    res = client.servers.update(resource_group_name, server_name, parameters)
    @response.set_response(:success, res)
  rescue MsRestAzure::AzureOperationError => e
    @response.set_response(:error, [], e.error_message, e.error_code)
  end

end
