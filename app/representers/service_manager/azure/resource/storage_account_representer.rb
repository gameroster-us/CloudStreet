module ServiceManager
  module Azure
    module Resource
      module StorageAccountRepresenter
        include Roar::JSON
        include Roar::Hypermedia
        include ServiceManager::Azure::ResourceRepresenter

        property :storage_type
        property :sku
        property :status_of_primary
        property :status_of_secondary
        property :access_tier
        property :sub_account_mec


        def sub_account_mec
          sub_account_mec_details = {'Blob' => 0, 'Queue' => 0, 'Table' => 0, 'File' => 0}
          if data['storage_sub_account_costs'].present?
            sub_account_mec_details['Blob'] =  (data['storage_sub_account_costs']['blob'] *24 * 30).round(2)
            sub_account_mec_details['Queue'] = (data['storage_sub_account_costs']['queue'] *24 * 30).round(2)
            sub_account_mec_details['Table'] = (data['storage_sub_account_costs']['table'] *24 * 30).round(2)
            sub_account_mec_details['File'] =  (data['storage_sub_account_costs']['file'] *24 * 30).round(2)
          end
          sub_account_mec_details
        end
      end
    end
  end
end
