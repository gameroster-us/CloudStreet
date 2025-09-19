class ProviderWrappers::Azure::StorageAccountProvider < ProviderWrappers::Azure

  def list
    res = client.storage_accounts.list
    # for old version of sdk @response.set_response(:success, res.value)
    @response.set_response(:success, res)
  rescue MsRestAzure::AzureOperationError => e
    @response.set_response(:error, [], e.error_message, e.error_code)
  end

  def list_by_resource_group(resource_group_name)
    res = client.storage_accounts.list_by_resource_group(resource_group_name)
    # for old version of sdk @response.set_response(:success, res.value)
    @response.set_response(:success, res)
  rescue MsRestAzure::AzureOperationError => e
    @response.set_response(:error, [], e.error_message, e.error_code)
  end

  def list_keys(resource_group_name, account_name)
    res = client.storage_accounts.list_keys(resource_group_name, account_name)
    @response.set_response(:success, res)
  rescue MsRestAzure::AzureOperationError => e
    @response.set_response(:error, [], e.error_message, e.error_code)
  end

  def get(resource_group_name, storage_account_name)
    res = client.storage_accounts.get_properties(resource_group_name, storage_account_name)
    @response.set_response(:success, res)
  rescue MsRestAzure::AzureOperationError => e
    @response.set_response(:error, [], e.error_message, e.error_code)
  end

  def delete(resource_group_name, storage_account_name)
    res = client.storage_accounts.delete(resource_group_name, storage_account_name)
    @response.set_response(:success, res)
  rescue MsRestAzure::AzureOperationError => e
    @response.set_response(:error, [], e.error_message, e.error_code)
  end

  def update_tags(resource_group_name, storage_account_name, parameters)
    parameters = build_model(Azure::Storage::Profiles::Latest::Mgmt::Models::StorageAccount, parameters)
    res = client.storage_accounts.update(resource_group_name, storage_account_name, parameters)
    @response.set_response(:success, res)
  rescue MsRestAzure::AzureOperationError => e
    @response.set_response(:error, [], e.error_message, e.error_code)
  end

  def list_blob_services(storage_account)
    res = client.blob_services.list(storage_account.resource_group_name, storage_account.name)
    @response.set_response(:success, res)
  rescue MsRestAzure::AzureOperationError => e
    @response.set_response(:error, [], e.error_message, e.error_code)
  end

end
