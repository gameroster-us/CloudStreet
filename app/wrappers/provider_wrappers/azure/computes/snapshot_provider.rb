class ProviderWrappers::Azure::Computes::SnapshotProvider < ProviderWrappers::Azure

  def list(resource_group_name)
    res = client.snapshots.list_by_resource_group(resource_group_name)
    @response.set_response(:success, res)
  rescue MsRestAzure::AzureOperationError => e
    @response.set_response(:error, [], e.error_message, e.error_code)
  end

  def get(resource_group_name, snapshot_name)
    res = client.snapshots.get(resource_group_name, snapshot_name)
    @response.set_response(:success, res)
  rescue MsRestAzure::AzureOperationError => e
    @response.set_response(:error, [], e.error_message, e.error_code)
  end

  def delete(resource_group_name, snapshot_name)
    res = client.snapshots.delete(resource_group_name, snapshot_name)
    @response.set_response(:success, res)
  rescue MsRestAzure::AzureOperationError => e
    @response.set_response(:error, [], e.error_message, e.error_code)
  end

  def update_tags(resource_group_name, snapshot_name, parameters)
    parameters = build_model(Azure::Compute::Profiles::Latest::Mgmt::Models::Snapshot, parameters)
    res = client.snapshots.update(resource_group_name, snapshot_name, parameters)
    @response.set_response(:success, res)
  rescue MsRestAzure::AzureOperationError => e
    @response.set_response(:error, [], e.error_message, e.error_code)
  end

end
