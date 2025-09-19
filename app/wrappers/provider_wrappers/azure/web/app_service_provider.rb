# App Service Provider
# https://docs.microsoft.com/en-us/rest/api/appservice/web-apps
class ProviderWrappers::Azure::Web::AppServiceProvider < ProviderWrappers::Azure
  def list(resource_group_name)
    fetch_response_from = 'value'
    relative_url = "subscriptions/#{@subscription_id}/resourceGroups/#{resource_group_name}/providers/Microsoft.Web/sites?api-version=2021-02-01"
    rest_client_helper(REST_CLIENT_BASE_URL, relative_url, GET, {}, fetch_response_from)
  end

  def update_tags(resource_group_name, resource_name, tags)
    body = tags.slice('tags')
    relative_url = "subscriptions/#{@subscription_id}/resourceGroups/#{resource_group_name}/providers/Microsoft.Web/sites/#{resource_name}?api-version=2021-02-01"
    rest_client_helper(REST_CLIENT_BASE_URL, relative_url, PATCH, body.to_json)
  end

  def delete(resource_group_name, resource_name)
    relative_url = "subscriptions/#{@subscription_id}/resourceGroups/#{resource_group_name}/providers/Microsoft.Web/sites/#{resource_name}?api-version=2021-02-01"
    rest_client_helper(REST_CLIENT_BASE_URL, relative_url, DELETE)
  end

  def get(resource_group_name, resource_name)
    relative_url = "subscriptions/#{@subscription_id}/resourceGroups/#{resource_group_name}/providers/Microsoft.Web/sites/#{resource_name}?api-version=2021-02-01"
    rest_client_helper(REST_CLIENT_BASE_URL, relative_url, GET)
  end

  def start
    relative_url = "subscriptions/#{@subscription_id}/resourceGroups/#{resource_group_name}/providers/Microsoft.Web/sites/#{resource_name}/start?api-version=2021-02-01"
    rest_client_helper(REST_CLIENT_BASE_URL, relative_url, POST)
  end

  def stop
    relative_url = "subscriptions/#{@subscription_id}/resourceGroups/#{resource_group_name}/providers/Microsoft.Web/sites/#{resource_name}/stop?api-version=2021-02-01"
    rest_client_helper(REST_CLIENT_BASE_URL, relative_url, POST)
  end

  def restart
    relative_url = "subscriptions/#{@subscription_id}/resourceGroups/#{resource_group_name}/providers/Microsoft.Web/sites/#{resource_name}/restart?api-version=2021-10-01"
    rest_client_helper(REST_CLIENT_BASE_URL, relative_url, POST)
  end

end
