module CloudTrail
  class RemoteServiceFetcherWorker
    include Sidekiq::Worker
    sidekiq_options queue: :cloud_trail, :retry => false, backtrace: true

    def perform(adapter_id, region_code, service_type, event_data)
    	adapter = Adapter.find(adapter_id)
      klass_name = service_type
      klass_name = "AWSRecords::Network::ElasticIP::AWS" if service_type == "AWSRecords::Network::ElasticIP::AWS"
    	remote_data = klass_name.constantize.get_remote_service_list(adapter, region_code, {})
    	$redis.hset("cloud_trail_remote_data","#{adapter_id}_#{region_code}_#{service_type}",remote_data.to_json)
    rescue Fog::AWS::Compute::Error, StandardError => e
      CTLog.info "!!!!!! Error in RemoteServiceFetcherWorker | adapter_id #{adapter_id} | region_code #{region_code} | klass #{service_type} | Error #{e.message} !!!!"
      $redis.hset("cloud_trail_remote_data","#{adapter_id}_#{region_code}_#{service_type}", {}.to_json)
    end
  end
end