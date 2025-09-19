class AWSRecords::Network::SecurityGroup::AWS < AWSRecords::Network::SecurityGroup
  SERVICE_CLASS = "Services::Network::SecurityGroup::AWS"
  REUSABLE  = true

  def self.is_ec2_classic_service?(attrs)
    attrs["vpc_id"].blank?
  end

  def set_provider_id
    self.provider_id = self.data["group_id"]
  end
  
  def self.set_provider_vpc_id(vpc_mapper, attributes)
    attributes[:provider_vpc_id] = attributes[:data]["vpc_id"]
    attributes
  end

  def create_or_update_synced_service_security_group
    SERVICE_CLASS.constantize.create_or_update_services_from_provider(self)
  end

  def fetch_remote_service(region_code)
    agent = ProviderWrappers::AWS::Networks::SecurityGroup.compute_agent(adapter, region_code)
    agent.security_groups.get(self.provider_id)
  end

  def build_or_edit_model_security_group(vpc)
    attributes = SecurityGroups::AWS.get_data_store_attributes(self)
    security_group = vpc.security_groups.where(group_id: provider_id,state: 'available').first

    if security_group
      security_group.set_attributes = attributes
    else
      security_group = vpc.security_groups.build(
        attributes.merge(
          type: 'SecurityGroups::AWS',
          vpc_id: vpc.vpc_id
        )
      )
    end
    security_group
  end

  class << self
    def build_or_edit_vpc_services_from_provider(vpc)
    end

    def build_or_edit_model_service_from_provider(vpc)
      SecurityGroups::AWS.save_service_from_aws(vpc){
        vpc.get_aws_records.security_groups.all.collect{|aws_record|
          OpenStruct.new(aws_record.data)
        }
      }
    end

    def get_remote_service_list(adapter, region_code, filters={})
      agent = ProviderWrappers::AWS::Networks::SecurityGroup.compute_agent(adapter, region_code)
      ProviderWrappers::AWS::Networks::SecurityGroup.all(agent, filters)
    end

    def fetch_remote_service(adapter, region_code, sg_id)
      agent = ProviderWrappers::AWS::Networks::SecurityGroup.compute_agent(adapter, region_code)
      agent.security_groups.get(sg_id)
    end

    def fetch_remote_service_by_id(adapter, region_code, sg_id)
      agent = ProviderWrappers::AWS::Networks::SecurityGroup.compute_agent(adapter, region_code)
      agent.security_groups.get_by_id(sg_id)
    end

    def format_service_data(service_data, adapter, region_code)
      service_type ||= service_data.class.to_s.split("AWS::").last
      service_data_json = JSON.parse(service_data.to_json)
      attributes = {
        adapter_id: adapter.id,
        region_id: Region.find_by(code: region_code).id,
        account_id: adapter.account_id,
        service_type: service_type,
        data: service_data_json,
        provider_id: service_data_json['group_id'],
        provider_vpc_id: service_data_json['vpc_id']
      }
      attributes
    end
  end
end