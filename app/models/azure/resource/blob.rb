# frozen_string_literal: true

module Azure
  # Blob storage service
  class Resource::Blob < Azure::Resource
    include Synchronizers::Azure
    store_accessor :data
    def storage_account
      Azure::Resource::StorageAccount.find_by_name(data['storage_account_name'])
    end
  end
end
