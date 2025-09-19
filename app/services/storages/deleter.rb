class Storages::Deleter < CloudStreetService
	
	def self.delete_s3_bucket(params , &block)
		storage = Storage.where(id: params[:storage_id]).first
		if storage.nil?
			status Status, :not_found, nil, &block
			return 
		end
		region_code = storage.region.code
		adapter = storage.adapter
		storage_connection = adapter.connection_storage(region_code)
		begin
			storages = Storage.where(key: storage.key, account_id: adapter.account_id)
			response = storage_connection.delete_bucket(storage.key)
			if response && response.status == 204
				storages.destroy_all
				SecurityScanStorage.where(provider_id: storage.key, adapter_id: adapter.id).delete_all
			else
				status Status, :error, "Something went wrong" , &block
				return "Something went wrong"
			end
		rescue Excon::Error::NotFound => e
			storages.destroy_all
			body = Hash.from_xml e.response.body
			message = "The specified bucket does not exist on s3. Deleted local entry."
			status Status, :not_found, message , &block
			return message			
		rescue Excon::Error => e
			body = Hash.from_xml e.response.body
			message = body["Error"]["Message"]
			status Status, :error, message , &block
			return message
		end	
		status Status, :success, storage, &block
	end
end