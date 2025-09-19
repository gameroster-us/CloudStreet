class AWSRecords::Network::Subnet::AWS < AWSRecords::Network::Subnet
  SERVICE_CLASS = "Services::Network::Subnet::AWS"
  REUSABLE  = true

  def set_provider_id
    self.provider_id = self.data["subnet_id"]
  end
  
  def self.set_provider_vpc_id(vpc_mapper, attributes)
    attributes[:provider_vpc_id] = attributes[:data]["vpc_id"]
    attributes
  end

  def fetch_remote_service(region_code)
    agent = ProviderWrappers::AWS::Networks::Subnet.compute_agent(adapter, region_code)
    agent.subnets.get(self.provider_id)
  end

  class << self
    def build_or_edit_model_service_from_provider(vpc)
      Subnets::AWS.save_service_from_aws(vpc){
        vpc.get_aws_records.subnets.all.collect{|aws_record| 
          OpenStruct.new(aws_record.data)
        }
      }
    end

    def get_remote_service_list(adapter, region_code, filters = {})
      agent = ProviderWrappers::AWS::Networks::Subnet.compute_agent(adapter, region_code)
      ProviderWrappers::AWS::Networks::Subnet.all(agent, filters)
    end

    def fetch_remote_service(adapter, region_code, subnet_id)
      agent = ProviderWrappers::AWS::Networks::Subnet.compute_agent(adapter, region_code)
      agent.subnets.get(subnet_id)
    end

    def format_service_data(service_data, adapter, region_code)
      service_type = service_data.class.to_s.split("AWS::").last
      service_data_json = JSON.parse(service_data.to_json)
      attributes = {
        adapter_id: adapter.id,
        region_id: Region.find_by(code: region_code).id,
        account_id: adapter.account_id,
        service_type: service_type,
        data: service_data_json,
        provider_id: service_data_json['subnet_id'],
        provider_vpc_id: service_data_json['vpc_id']
      }
      attributes
    end
  end
end
