# https://learn.microsoft.com/en-us/rest/api/mysql/#flexible-server-rest-operations
class ProviderWrappers::Azure::Databases::Mysql::ServerProvider < ProviderWrappers::Azure

  # Currently, we have replaced the SDK call with a REST API call for MySQL, so we have ignored the code below
  # def list(resource_group_name)
  #   res = client.servers.list_by_resource_group(resource_group_name)
  #   @response.set_response(:success, res.value)
  # rescue MsRestAzure::AzureOperationError => e
  #   @response.set_response(:error, [], e.error_message, e.error_code)
  # end

  # def get(resource_group_name, server_name)
  #   res = client.servers.get(resource_group_name, server_name)
  #   @response.set_response(:success, res)
  # rescue MsRestAzure::AzureOperationError => e
  #   @response.set_response(:error, [], e.error_message, e.error_code)
  # end

  # def delete(resource_group_name, server_name)
  #   res = client.servers.delete(resource_group_name, server_name)
  #   @response.set_response(:success, res)
  # rescue MsRestAzure::AzureOperationError => e
  #   @response.set_response(:error, [], e.error_message, e.error_code)
  # end

  # def update_tags(resource_group_name, server_name, parameters)
  #   parameters = build_model(Azure::Mysql::Profiles::Latest::Mgmt::Models::Server, parameters)
  #   res = client.servers.update(resource_group_name, server_name, parameters)
  #   @response.set_response(:success, res)
  # rescue MsRestAzure::AzureOperationError => e
  #   @response.set_response(:error, [], e.error_message, e.error_code)
  # end

  def list(resource_group_name)
    fetch_response_from = 'value'
    relative_url = "subscriptions/#{@subscription_id}/resourceGroups/#{resource_group_name}/providers/Microsoft.DBforMySQL/flexibleServers?api-version=2023-06-01-preview"
    rest_client_helper(REST_CLIENT_BASE_URL, relative_url, GET, {}, fetch_response_from)
  end

  def update_tags(resource_group_name, server_name, tags)
    body = tags.slice('tags')
    relative_url = "subscriptions/#{@subscription_id}/resourceGroups/#{resource_group_name}/providers/Microsoft.DBforMySQL/flexibleServers/#{server_name}?api-version=2023-06-01-preview"
    rest_client_helper(REST_CLIENT_BASE_URL, relative_url, PATCH, body.to_json)
  end

  def delete(resource_group_name, server_name)
    relative_url = "subscriptions/#{@subscription_id}/resourceGroups/#{resource_group_name}/providers/Microsoft.DBforMySQL/flexibleServers/#{server_name}?api-version=2023-06-01-preview"
    rest_client_helper(REST_CLIENT_BASE_URL, relative_url, DELETE)
  end

  def get(resource_group_name, server_name)
    relative_url = "subscriptions/#{@subscription_id}/resourceGroups/#{resource_group_name}/providers/Microsoft.DBforMySQL/flexibleServers/#{server_name}?api-version=2023-06-01-preview"
    rest_client_helper(REST_CLIENT_BASE_URL, relative_url, GET)
  end

end
