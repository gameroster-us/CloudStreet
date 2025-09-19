class ProviderWrappers::Azure::Computes::DiskProvider < ProviderWrappers::Azure

  def list(resource_group_name)
    # res = client.disks.list_by_resource_group(resource_group_name)
    # @response.set_response(:success, res)
    subscription_id ||= client.subscription_id
    relative_url = "subscriptions/#{subscription_id}/resourceGroups/#{resource_group_name}/providers/Microsoft.Compute/disks?api-version=2020-12-01"
    res = self.class.request_rest_client(subscription_id, relative_url)
    @response.set_response(:success, res['value'])
  rescue MsRestAzure::AzureOperationError => e
    @response.set_response(:error, [], e.error_message, e.error_code)
  end

  def get(resource_group_name, disk_name)
    # res = client.disks.get(resource_group_name, disk_name)
    # @response.set_response(:success, res)
    subscription_id ||= client.subscription_id
    relative_url = "subscriptions/#{subscription_id}/resourceGroups/#{resource_group_name}/providers/Microsoft.Compute/disks/#{disk_name}?api-version=2020-12-01"
    res = self.class.request_rest_client(subscription_id, relative_url)
    @response.set_response(:success, res)
  rescue MsRestAzure::AzureOperationError => e
    @response.set_response(:error, [], e.error_message, e.error_code)
  end

  def delete(resource_group_name, disk_name)
    res = client.disks.delete(resource_group_name, disk_name)
    @response.set_response(:success, res)
  rescue MsRestAzure::AzureOperationError => e
    @response.set_response(:error, [], e.error_message, e.error_code)
  end

  def update_tags(resource_group_name, disk_name, parameters)
    parameters = build_model(Azure::Compute::Profiles::Latest::Mgmt::Models::Disk, parameters)
    res = client.disks.update(resource_group_name, disk_name, parameters)
    @response.set_response(:success, res)
  rescue MsRestAzure::AzureOperationError => e
    @response.set_response(:error, [], e.error_message, e.error_code)
  end

end
