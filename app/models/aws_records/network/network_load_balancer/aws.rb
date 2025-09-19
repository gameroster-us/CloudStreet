class AWSRecords::Network::NetworkLoadBalancer::AWS < AWSRecord

  class << self

    def get_remote_service_list(adapter, region_code, filters={})
    CSLogger.info "---------Started fetching Network LoadBalancers from AWS for #{adapter.name} in #{region_code}----"
      service_type = "network"
      v2_elb_client = adapter.connection_v2_elb_client(region_code)
      all_lbs = v2_elb_client.describe_load_balancers({})
      res = all_lbs.load_balancers.each_with_object([]) { |record, arr| arr.push(record) if record.type.eql?(service_type); }
      res
    rescue StandardError => error
      CSLogger.error "===Network LB Error Here==========#{error.message}========"
    end

  end

end
